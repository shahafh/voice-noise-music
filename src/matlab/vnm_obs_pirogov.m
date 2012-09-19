function [dborders, borders, borders_ind, obs]=vnm_obs_pirogov(x, alg, algs, etc_info)
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки');
		if dlg_name==0
			return;
		end
		file_name=fullfile(dlg_path,dlg_name);
		[x,fs]=vb_readwav(file_name);
		algs.obs_general=	struct(	'frame_size',0.030, 'frame_step',0.010, 'fs',11025);
		alg=				struct(	'avr',0.020,	'diff',0.040,	'max_threshold',0.7,	'max_neighborhood',0.060,	'reg_sz',[0.045 0.250]);
		if fs~=algs.obs_general.fs
			x=resample(x, algs.obs_general.fs, fs);
		end
	else
		file_name='signal';
	end

	x(:,2:end)=[];

	if etc_info.obs_sz<1
		dborders=[];
		borders=[];
		borders_ind=[];
		obs=[];
		return
	end

	lpc_ord=round(algs.obs_general.fs/1000)+4;
	spec=zeros(etc_info.obs_sz, 128);
	powr=zeros(etc_info.obs_sz, 1);

	obs_ind=0;
	for i=1:etc_info.fr_sz(1):size(x,1)-etc_info.fr_sz(2)+1
		obs_ind=obs_ind+1;
		cur_x=x(i:i+etc_info.fr_sz(2)-1).*gausswin(etc_info.fr_sz(2));
		[cur_a,cur_e]=vnm_lpc(cur_x, lpc_ord);
		spec(obs_ind,:)=20*log10(abs( freqz( sqrt(cur_e), cur_a, size(spec,2) ) + 10^(-90/20) ));
		powr(obs_ind)=cur_x'*cur_x;
	end
	
	not_powr=powr<quantile(powr, 0.25);
	spec(not_powr,:)=repmat(mean(spec(not_powr,:)), sum(not_powr), 1);

	obs=mean(spec,2);

	avr_sz=max(1, round(alg.avr / algs.obs_general.frame_step));
	avr_diff_b=1;
	if avr_sz>1
		avr_diff_b=ones(1,avr_sz)/avr_sz;

		% spec need only for display purposes
		if nargout<1
			avr_delay=fix(avr_sz/2-0.5);
			spec=filter(avr_diff_b, 1, [spec; zeros(avr_delay,size(spec,2))]);
			spec(1:avr_delay,:)=[];
		end
	end

	delay_sz=max(1, round(alg.diff / algs.obs_general.frame_step));
	avr_diff_b=conv(avr_diff_b,[1 zeros(1,delay_sz-2) -1]);
	avr_diff_delay=fix(length(avr_diff_b)/2-0.5);

	obs=filter(avr_diff_b,1,[obs; zeros(avr_diff_delay,1)]);
	obs(1:avr_diff_delay)=[];
	obs(1:avr_diff_delay)=0;
	obs(end-avr_diff_delay+1:end)=0;

	obs=obs/(std(obs)+eps);

	maxneigh=max(1,round(alg.max_neighborhood/algs.obs_general.frame_step));
	obs_max=[obs zeros(size(obs,1),maxneigh*2)];
	for i=1:maxneigh
		obs_max(i+1:end,i*2)=  obs(1:end-i);
		obs_max(1:end-i,i*2+1)=obs(i+1:end);
	end
	[mxv,mxi]=max(obs_max,[],2);
	[mnv,mni]=min(obs_max,[],2);
	borders_ind=sort([find(mxi==1 & mxv>alg.max_threshold); ...
			 find(mni==1 & mnv<-alg.max_threshold)]);

	min_reg_sz=alg.reg_sz(1)/algs.obs_general.frame_step;
	check_ok=false;
	while not(check_ok)
		check_ok=true;
		for i=1:numel(borders_ind)-1
			if borders_ind(i+1)-borders_ind(i)<min_reg_sz
				[~,mi]=min(abs(obs(borders_ind([i i+1]))));
				borders_ind(i+mi-1)=[];
				check_ok=false;
				break;
			end
		end
	end

	borders=((borders_ind-1)*etc_info.fr_sz(1)+etc_info.fr_sz(2)/2)/algs.obs_general.fs;
	dborders=diff(borders);
	dborders(dborders<alg.reg_sz(1) | dborders>alg.reg_sz(2))=[];

	if length(dborders)<2
		disp(['vnm_OBS_PIROGOV: Too few output observations in ' etc_info.file_name]);
	end

	if nargout<1
		dbrd=dborders(dborders<alg.reg_sz(2));
		titl={'Статистические характеристики длительности "фонем"' sprintf('%s: количество %d, среднее %f, медиана %f, СКО %f, темп %f', file_name, numel(dbrd), mean(dbrd), median(dbrd), std(dbrd), 1/mean(dbrd))};

		figure;
		[hy, hx]=hist(dbrd,40);
		hy=hy/sum(hy);
		subplot(2,1,1);
		bar(hx,hy);
		grid on;
		title(titl, 'interpreter','none');
		subplot(2,1,2);
		plot(hx,cumsum(hy));
		grid on;

		figure('units','pixels', 'position',get(0,'screensize'));
		subplot(4,1,1);
		plot((0:size(x,1)-1)/algs.obs_general.fs, x);
		title(titl, 'interpreter','none');
		grid on;
		x_lim=[0 (size(x,1)-1)/algs.obs_general.fs];
		xlim(x_lim);
		y_lim=max(abs(x))*1.2*[-1 1];
		for i=1:length(borders)
			line(borders(i)+[0 0], y_lim, 'Color','k');
		end
		ylim(y_lim);

		subplot(4,1,2);
		obs_t=((0:size(spec,1)-1)*etc_info.fr_sz(1)+etc_info.fr_sz(2)/2)/algs.obs_general.fs;
		imagesc(obs_t, (0:size(spec,2)-1)*algs.obs_general.fs/(2*(size(spec,2)-1)), spec');
		axis xy;
		xlim(x_lim);
		y_lim=ylim();
		for i=1:length(borders)
			line(borders(i)+[0 0], y_lim, 'Color','k');
		end
		ylim(y_lim);

		subplot(4,1,3);
		plot(obs_t, obs);
		grid on;
		xlim(x_lim);
		y_lim=ylim();
		line(xlim, alg.max_threshold+[0 0], 'Color','m');
		line(xlim, -alg.max_threshold+[0 0], 'Color','m');
		for i=1:length(borders)
			line(borders(i)+[0 0], y_lim, 'Color','k');
		end
		ylim(y_lim);

		stat_sz=4;
		stat_st=0.01;
		tempo_x=[];
		tempo_y=[];
		for stat_pos=0:stat_st:x_lim(2)-stat_sz
			cur_brd=borders(borders>=stat_pos & borders<stat_pos+stat_sz);
			if isempty(cur_brd)
				tempo_x(end+1)=stat_pos+stat_sz/2; %#ok<AGROW>
				tempo_y(end+1)=0; %#ok<AGROW>
			else
				tempo_x(end+1)=(cur_brd(1)+cur_brd(end))/2; %#ok<AGROW>
				cur_dbrd=diff(cur_brd);
				cur_dbrd=cur_dbrd(cur_dbrd<alg.reg_sz(2));
				tempo_y(end+1)=1/median(cur_dbrd); %#ok<AGROW>
			end
		end
		subplot(4,1,4);
		plot(tempo_x, tempo_y);
		xlim(x_lim);
		grid on;

		set(zoom,'ActionPostCallback',@on_zoom_pan);
		set(pan ,'ActionPostCallback',@on_zoom_pan);
		zoom xon;
		set(pan, 'Motion', 'horizontal'); 

		clear obs dborders;
	end
end
