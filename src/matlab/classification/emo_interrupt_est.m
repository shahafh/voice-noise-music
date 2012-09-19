function vnm_interrupt_est(dir_in, dir_out)
	disp('vnm_interrupt_est 0.0.0.2');
	if nargin~=2
		disp('Usage: vnm_interrupt_est <dir_in> <dir_out>');
		return;
	end

	alg.obs.general=	struct(	'frame_size',0.030, 'frame_step',0.010, ...
								'filter',struct('band',[1000 3400], 'order',10));
	alg.vad=	struct(	'power_quantile',0.3, 'rel_threshold_db',-30, 'abs_threshold_db',-60, 'min_pause',0.300, 'min_speech',0.400);

	files_list=dir([dir_in filesep '*.wav']);
	files_list([files_list.isdir])=[];

	for i=1:length(files_list)
		process_file(dir_in, dir_out, files_list(i).name, alg);
	end
end

function process_file(dir_in, dir_out, file_name, alg)
	[x,fs]=vb_readwav([dir_in filesep file_name]);

	if size(x,2)~=2
		fprintf('File %s%s%s not a stereo.\n', dir_in, filesep, file_name);
		return;
	end

	if isfield(alg.obs.general,'fs') && fs~=alg.obs.general.fs
		x=resample(x, alg.obs.general.fs, fs_in);
		fs=alg.obs.general.fs;
	else
		alg.obs.general.fs=fs;
	end

	if isfield(alg.obs.general,'snr')
		x=awgn(x, alg.obs.general.snr, 'measured');
	end

	if isfield(alg.obs.general,'preemphasis') && alg.obs.general.preemphasis>0
		x=filter([1 -alg.obs.general.preemphasis], 1, x);
	end

	if isfield(alg.obs.general,'filter') && alg.obs.general.filter.order>0
		filt_ord=alg.obs.general.filter.order;

		if alg.obs.general.filter.band(2)>=fs/2-100
			filt_info = { alg.obs.general.filter.band(1)*2/fs, 'high' };
		else
			filt_info = { alg.obs.general.filter.band*2/fs };
		end

		while filt_ord>0
			[filt_b, filt_a]=butter(filt_ord, filt_info{:});
			if isfilterstable(filt_a)
				break;
			else
				filt_ord=filt_ord-1;
			end
		end
		if filt_ord~=alg.obs.general.filter.order
			fprintf('Filter order was decreased from %d to %d.', alg.obs.general.filter.order, filt_ord);
		end

		x=filtfilt(filt_b, filt_a, x);
	end

	fr_sz=round([alg.obs.general.frame_step alg.obs.general.frame_size]*alg.obs.general.fs);
	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);

	vad_sign=zeros(obs_sz,size(x,2));
	for ch=1:size(x,2)
		vad_sign(:,ch)=is_speech(x(:,ch), alg);
	end

	cur_out=[dir_out filesep file_name '.interrupt'];
	fid=fopen(cur_out,'w');
	if fid==-1
		fprintf('Can''t open ouput file %s\n',cur_out);
	else
		v_and=vad_sign(:,1)&vad_sign(:,2);
		v_or= vad_sign(:,1)|vad_sign(:,2);
		up_cnt=sum(diff([false; v_and])==1);
		fprintf(fid, 'SimultaneousSpeechTime(value_sec,norm_to_vad_length):\t%f\t%f\n', sum(v_and)*alg.obs.general.frame_step, sum(v_and)/sum(v_or));
		fprintf(fid, 'SimultaneousSpeechCount(value_num,norm_to_ch0_regs):\t%d\t%f\n', up_cnt,  up_cnt/sum(diff([false; vad_sign(:,1)])==1) );
		fclose(fid);
	end

%	figure('Units','normalized', 'Position',[0 0 1 1]);
%	x_t=(0:size(x,1)-1)/fs;
%	obs_time=((0:obs_sz-1)'*fr_sz(1)+fr_sz(2)/2)/alg.obs.general.fs;
%	plot(x_t,x(:,1)+0.5,'b', x_t,x(:,2)-0.5,'b', obs_time,vad_sign(:,1)+0.1,'r', obs_time,vad_sign(:,2)-1.1,'r');
%	title(file_name,'Interpreter','none');
%	grid on;
%	zoom xon;
end

function cur_is_speech=is_speech(x, alg)
	fr_sz=round([alg.obs.general.frame_step alg.obs.general.frame_size]*alg.obs.general.fs);
	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);
	cur_power=zeros(obs_sz,1);

	obs_ind=0;
	for i=1:fr_sz(1):size(x,1)-fr_sz(2)+1
		cur_x=x(i:i+fr_sz(2)-1);
		obs_ind=obs_ind+1;
		cur_power(obs_ind)=mean(cur_x.*cur_x);
	end
	cur_power=10*log10(cur_power + 1e-100);
	cur_power_max=max(cur_power);

	power_threshold=-inf;
	if isfield(alg.vad,'power_quantile')
		power_threshold=max(power_threshold, quantile(cur_power,alg.vad.power_quantile));
	end
	if isfield(alg.vad,'rel_threshold_db')
		power_threshold=max(power_threshold, cur_power_max+alg.vad.rel_threshold_db);
	end
	if isfield(alg.vad,'abs_threshold_db')
		power_threshold=max(power_threshold, alg.vad.abs_threshold_db);
	end

	cur_is_speech=cur_power>power_threshold;

	cur_is_speech=find_regions(cur_is_speech, ...
						round(alg.vad.min_pause/alg.obs.general.frame_step), ...
						round(alg.vad.min_speech/alg.obs.general.frame_step));
end
