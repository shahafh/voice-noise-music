function vnm_main()
	alg=vnm_classify_cfg();
%{
	if not(isfield(alg,'matlabpool'))
		local_jm=findResource('scheduler','type','local');
		if local_jm.ClusterSize>1
			alg.matlabpool={'local'};
		end
	end
%}
	vnm_classify('d:\Bases\Berlin\data','berlin',alg);
end
