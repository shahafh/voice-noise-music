function obs=vnm_obs_interrupt(x, alg, algs, etc_info) %#ok<INUSL>
	if isfield(alg,'load_cached') && alg.load_cached && exist([etc_info.file_name '.interrupt'], 'file')
		% Just load cached observations
		[~,obs(1,:),obs(2,:)]=textread([etc_info.file_name '.interrupt'], '%s%n%n'); %#ok<REMFF1>
		obs=obs(:)';
		return;
	end

	[x,fs]=vb_readwav(etc_info.file_name);

	if size(x,2)~=2
		error('emo:obs:interrupt:wavread', 'File %s not a stereo.', etc_info.file_name);
	end

	if isfield(alg.obs_general,'fs') && fs~=alg.obs_general.fs
		x=resample(x, alg.obs_general.fs, fs);
		fs=alg.obs_general.fs;
	else
		alg.obs_general.fs=fs;
	end

	if isfield(alg.obs_general,'snr')
		x=awgn(x, alg.obs_general.snr, 'measured');
	end

	if isfield(alg.obs_general,'preemphasis') && alg.obs_general.preemphasis>0
		x=filter([1 -alg.obs_general.preemphasis], 1, x);
	end

	filt.order=0;
	if isfield(alg.obs_general,'filter') && alg.obs_general.filter.order>0
		filt=alg.obs_general.filter;
	end
	if isfield(alg,'filter') && alg.filter.order>0
		filt=alg.filter;
	end

	if filt.order>0
		filt_ord=filt.order;

		if filt.band(2)>=fs/2-100
			filt_info = { filt.band(1)*2/fs, 'high' };
		else
			filt_info = { filt.band*2/fs };
		end

		while filt_ord>0
			[filt_b, filt_a]=butter(filt_ord, filt_info{:});
			if isfilterstable(filt_a)
				break;
			else
				filt_ord=filt_ord-1;
			end
		end
		if filt_ord~=filt.order
			fprintf('Filter order was decreased from %d to %d.', filt.order, filt_ord);
		end

		x=filtfilt(filt_b, filt_a, x);
	end

	fr_sz=round([alg.obs_general.frame_step alg.obs_general.frame_size]*alg.obs_general.fs);
	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);

	vad_sign=zeros(obs_sz,size(x,2));
	for ch=1:size(x,2)
		vad_sign(:,ch)=is_speech(x(:,ch), alg);
	end

	v_and=vad_sign(:,1)&vad_sign(:,2);
	v_or= vad_sign(:,1)|vad_sign(:,2);
	up_cnt=sum(diff([false; v_and])==1);
	obs=[sum(v_and)*alg.obs_general.frame_step, sum(v_and)/sum(v_or) up_cnt,  up_cnt/sum(diff([false; vad_sign(:,1)])==1)];
end

function cur_is_speech=is_speech(x, alg)
	fr_sz=round([alg.obs_general.frame_step alg.obs_general.frame_size]*alg.obs_general.fs);
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

	cur_is_speech=find_regions(cur_power>power_threshold, ...
						round(alg.vad.min_pause/alg.obs_general.frame_step), ...
						round(alg.vad.min_speech/alg.obs_general.frame_step));
end
