classdef vnm_classifier_gmm
	%vnm_CLASSIFIER_GMM Kolmogorov-Smirnov distance GMM classifier
	%   Calculates Kolmogorov-Smirnov distances between cumulative distribution
	%   functions and classify incoming objects by these distances by GMM

	%   Author(s): A.G.Davydov
	%   $Revision: 1.0.0.1 $  $Date: 2011/08/09 16:29:55 $ 

	properties
		classes;
		cdf;
		gmm;
	end

	methods(Access='protected')
		function obj=vnm_classifier_gmm()
		end
	end

	methods(Static)
		function obj=train(train_dat, train_grp, etc_data, cl_alg) %#ok<INUSL,INUSD>
			obj=vnm_classifier_gmm;

			gmm_opt_arg={};
			if nargin>=4 && isfield(cl_alg, 'gmm_opt_arg')
				gmm_opt_arg=cl_alg.gmm_opt_arg;
			end

			obj.classes=etc_data.cl_name;
			obj.cdf=	etc_data.cl_cdf;

			obj.gmm=cell(numel(obj.classes),1);
			for cl_i=1:numel(obj.classes)
				obj.gmm{cl_i}=gmdistribution.fit(multi_cdf.cdfs_dist(obj.cdf(cl_i),etc_data.cl_obs{cl_i}), gmm_opt_arg{:});
			end
		end
	end

	methods
		function cl_res=classify(obj, test_dat)
			cl_res=cell(size(test_dat));
			for obs_i=1:numel(test_dat)
				cur_pdf=zeros(size(obj.gmm));
				for cl_i=1:numel(obj.gmm)
					cur_pdf(cl_i)=obj.gmm{cl_i}.pdf( multi_cdf.cdfs_dist(obj.cdf(cl_i),test_dat(obs_i)));
				end
				[~,mi]=max(cur_pdf);
				cl_res(obs_i)=obj.classes(mi);
			end
		end
	end
end
