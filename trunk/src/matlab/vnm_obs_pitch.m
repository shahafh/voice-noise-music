function obs=vnm_obs_pitch(x, alg, algs, etc_info) %#ok<INUSD>
	if isfield(alg,'normalize') && alg.normalize
		x=x*0.95/max(abs(x));
	end

	if isfield(alg,'grundton3_cfg')
		marks=emosdk_wrp('grundton3.dll',x,algs.obs_general.fs,[5 6],alg.grundton3_cfg);

		marks5=marks{1};
		marks6=marks{2};
		marks6(marks6(:,2)<=0,:)=[];
		obs=zeros(size(marks5,1),1);
		for i=1:size(marks6,1)
			obs(marks6(i,1)==marks5(:,1))=marks6(i,2);
		end
	else
		sfs_alg.frame_step_smpl=round(alg.obs_general.frame_step*alg.obs_general.fs);
		sfs_alg.frame_size_smpl=round(alg.obs_general.frame_size*alg.obs_general.fs);
		[obs, ~, tone]=sfs_rapt(x*0.9/max(abs(x)),algs.obs_general.fs, sfs_alg); %#ok<NASGU>
%		obs = obs(abs(obs-mean(obs)) <= 3*std(obs));
%		obs = [obs,tone];, 
	end

	if isfield(alg,'log') && alg.log
		ind=obs>0;
		obs(ind)=log(obs(ind));
	end
end
