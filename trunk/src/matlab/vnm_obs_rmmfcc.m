function obs = vnm_obs_rmmfcc(x, alg, algs, etc_info)
%vnm_OBS_MFCC Calculate Mel-frequency cepstral coefficients by RASTAMAT (http://labrosa.ee.columbia.edu/matlab/rastamat/)

	obs = transpose(rm_melfcc(x*3.3752, algs.obs_general.fs, 'maxfreq', 4000, 'numcep', alg.order, 'nbands', 20, ...
					'fbtype', 'fcmel', 'dcttype', 1, 'usecmp', 1, 'wintime', algs.obs_general.frame_size, ...
					'hoptime',algs.obs_general.frame_step, 'preemph',alg.preemphasis, 'dither', 1));

	if size(obs,1)~=etc_info.obs_sz
		warning('emo:obs:mfcc:wrong_size','Incorrect MFCC length in file "%s": %d (actual) vs %d (required).', etc_info.file_name, size(obs,1),etc_info.obs_sz);
		obs=[obs; repmat(obs(end,:),etc_info.obs_sz-size(obs,1)-1,1)];
		obs(etc_info.obs_sz:end,:)=[];
	end
end
