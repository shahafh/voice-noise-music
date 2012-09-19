function vnm_dll_stat(dir_path)
	cache_file='vnm_dll_cache.mat';
	if exist(cache_file,'file') && strcmp(questdlg('Open cached data?','Cached results','Yes','No','Yes'),'Yes')
		load(cache_file);
		pause(0.2);
	else
		pause(0.2);

		if nargin<1
			dir_path=uigetdir('','Выберите базу');
			if not(dir_path)
				return;
			end
		end

		experts_file=[dir_path filesep 'experts.txt'];
		if exist(experts_file,'file')
			[tbl{1:11}]=textread(experts_file,'%d%d%d%d%d%d%d%d%d%d%d');
			tbl=cell2mat(tbl);
			emo.name=[];
			emo(1)=[];
			for i=1:size(tbl,1)
				cur_mask=sprintf('%08d%06d_*.wav',tbl(i,[1 2]));
				cur_files=dir([dir_path filesep cur_mask]);
				if length(cur_files)==1
					emo(end+1).name=cur_files.name;
					emo(end).est=tbl(i,5);
				else
					fprintf('Ambiguous mask %s with esimations %d_%d (skiped)\n', cur_mask,tbl(i,[5 6]));
					for j=1:length(cur_files)
						fprintf('%s\n',cur_files(j).name);
					end
				end
			end
			one_color=false;
		else
			emo=dir(dir_path);
			emo([emo.isdir])=[];
			for i=1:length(emo)
				emo(i).est=1;
			end
			one_color=true;
		end

		vnm_name='grundton';
		gt_cfg.frame_step=		0.005; % 0.010
		gt_cfg.frame_size=		0.040;
		gt_cfg.f0_range_min=	50;
		gt_cfg.f0_range_max=	800;

		gt_cfg.harm_freq=		3000;
		gt_cfg.harm_win=		true;
		gt_cfg.harm_lpc=		true;
		gt_cfg.harm_fs_mul=		1;

		gt_cfg.fine_do=			true;
		gt_cfg.fine_win=		true;
		gt_cfg.fine_lpc=		false;
		gt_cfg.fine_fs_mul=		1;
		gt_cfg.fine_part=		0.05;

		gt_cfg.dp_dt0_max=		0.05;
		gt_cfg.dp_look_up=		0.100;
		gt_cfg.dp_sum_factor=	1.07;

		gt_cfg.tone_vocal=		0.50;
		gt_cfg.tone_power=		-40;
		gt_cfg.tone_reg_vocal=	0.060;
		gt_cfg.tone_reg_unvocal=0.040;

		f0_freq_max_sz=10.0/2/gt_cfg.frame_step; % (10 sec./ 2 (V-U) / frame_step)

		vnm_obs=cell(size(emo));
		gt_obs=cell(size(emo));
		parfor ei=1:length(emo)
			[x,fs]=vb_readwav([dir_path filesep emo(ei).name]);
			x(:,2:end)=[];

			[f0_freq, ~, f0_tone]=f0_grundton(x, fs, gt_cfg);
			f0_freq(not(f0_tone))=[];
			f0_freq(1:fix(length(f0_freq)/2))=[];
%			if length(f0_freq)>f0_freq_max_sz % save only last record part
%				f0_freq(1:end-f0_freq_max_sz)=[];
%			end
			gt_obs{ei}=f0_freq;


%			vnm_obs{ei}=vnm_dll_call(x,fs,10);
%			f0_med=median(f0_freq);
			vnm_obs{ei}=f0_freq; %(f0_freq-f0_med)/f0_med;
		end

		for ei=1:length(emo)
			emo(ei).obs=vnm_obs{ei};
		end

		gt_med=cellfun(@median, gt_obs);
%		emo(gt_med<150)=[];

		save(cache_file);
	end

	figure('Units','pixels', 'Position',get(0,'ScreenSize'));
	colors={[1 0 0],[0.9 0.9 0],[0 0.7 0],[0.5 0.5 1]};
	est_rg=[inf -inf];
	
	if one_color
		colors=uisetcolor([0.5 0.5 0.5]);
		if length(colors)~=3
			colors=[0.5 0.5 0.5];
		end
		colors={colors};
	end

	for ei=1:length(emo)
		if isempty(emo(ei).name)
			continue;
		end
		cur_obs=emo(ei).obs;
		if isempty(cur_obs)
			disp(['No data in file ' emo(ei).name]);
			continue;
		end
		cur_clr=colors{emo(ei).est};

		cur_rg=quantile(cur_obs, [0.05 0.95]);
		est_rg=[min(est_rg(1),cur_rg(1)) max(est_rg(2),cur_rg(2))];

%		cur_val=quantile(cur_obs,0.25);
%		cur_cl=find(cur_val<borders,1);
%		disp([emo(ei).fname ' ' num2str(cur_val) ' ' num2str(emo(ei).expert) '(expert) vs ' num2str(cur_cl) '(estimation)']);

		[cur_f,cur_x]=ecdf(cur_obs);
		plot(cur_x,cur_f,'Color',cur_clr);
		hold on;
	end

	title(vnm_name, 'Interpreter','none');
	grid on;
	xlim(est_rg);
end
