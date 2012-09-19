function obs=vnm_obs_borders(x, alg, algs, etc_info) %#ok<INUSD>
	if isfield(alg,'normalize') && alg.normalize
		x=x*0.95/max(abs(x));
	end

	marks=emosdk_wrp('grundton3.dll',x,algs.obs_general.fs,3,alg.grundton3_cfg);
	obs=marks{1};
	obs(:,1)=obs(:,1)/algs.obs_general.fs;
end
