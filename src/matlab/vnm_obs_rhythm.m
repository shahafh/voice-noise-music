function obs=vnm_obs_rhythm(x, alg, etc_info)

%	alg.obs_general.filter.band = [300 4000];
	filt_band=alg.obs_general.filter.band;
%	alg.obs_general.filter.order = 6;
	filt_ord=alg.obs_general.filter.order;

	if filt_ord > 0
		if filt_band(2)>=alg.obs_general.fs/2-100
			filt_info = { filt_band(1)*2/alg.obs_general.fs, 'high' };
		else
			filt_info = { filt_band*2/alg.obs_general.fs };
		end

		while filt_ord>0
			[filt_b, filt_a]=butter(filt_ord, filt_info{:});
			if isfilterstable(filt_a)
				break;
			else
				filt_ord=filt_ord-1;
			end
		end

		x=filtfilt(filt_b, filt_a, x);
	end

%	fr_sz=round([alg.obs_general.frame_step alg.obs_general.frame_size]*alg.obs_general.fs);
%	obs_sz=fix((size(x,1)-fr_sz(2))/fr_sz(1)+1);
%	obs=zeros(obs_sz,3);

	%% Calculate power
	obs_power=vnm_obs_power(x, alg, etc_info);
	fr_sz=round([alg.obs_general.frame_step alg.obs_general.frame_size]*alg.obs_general.fs);
	obs_time=((0:size(obs_power,1)-1)*fr_sz(1)+fr_sz(2)/2)/alg.obs_general.fs; % must be vector row!!! (line 32: in case size(obs_speech_reg)=[1,2])

	%% VAD and speech regions
	[obs_vad, obs_speech_ind]=find_regions(obs_power > max( quantile(obs_power,alg.meta_obs.vad.power_quantile), alg.meta_obs.vad.power_threshold ), ...
								round(alg.meta_obs.vad.min_pause/alg.obs_general.frame_step), ...
								round(alg.meta_obs.vad.min_speech/alg.obs_general.frame_step));
	obs_speech_reg=obs_time(obs_speech_ind);

	if size(obs_speech_reg,1)==2 && size(obs_speech_reg,1)==1
		fprintf('File %s rhythm calculation error.\n', etc_info.file_name);
	end

	if isempty(obs_speech_reg)
		fprintf('File %s have no rhythm observations.\n', etc_info.file_name);
		obs=zeros(0,2);
	else
		obs=[obs_speech_reg(:,2)-obs_speech_reg(:,1), [obs_speech_reg(2:end,1)-obs_speech_reg(1:end-1,2); 0]];
	end

	if nargout<1 || (isfield(alg.obs.rhythm,'is_disp') && alg.obs.rhythm.is_disp)
		figure('Units','normalized', 'Position',[0 0 1 1]);
		plot((0:size(x,1)-1)/alg.obs_general.fs, x);
		mxv=max(abs(x));
		hold('on');
		plot(obs_time, obs_vad*mxv, 'r');
		axis([0 (size(x,1)-1)/alg.obs_general.fs mxv*1.1*[-1 1]]);
		grid('on');
		zoom('xon');
		set(pan, 'Motion', 'horizontal');
	end
end
