classdef vnm_classifier_wks_libsvm
	%vnm_CLASSIFIER_WKS_LIBSVM Kolmogorov-Smirnov distance SVM classifier
	%   Calculates Kolmogorov-Smirnov distances between cumulative distribution
	%   functions and classify incoming objects by these distances using
	%   libSVM.
    %   Supports multi-class classification tasks.

	properties
		cdf;
		svm;
	end

	methods(Access='protected')
		function obj=vnm_classifier_wks_libsvm()
		end
	end

	methods(Static)
		function obj=train(train_dat, train_grp, etc_data, cl_alg)
			obj=vnm_classifier_wks_libsvm;

			obj.cdf=etc_data.cl_cdf;

			libsvm_opt_arg='';
			if nargin>=4 && isfield(cl_alg, 'libsvm_opt_arg')
				libsvm_opt_arg=cl_alg.libsvm_opt_arg;
			end
			obj.svm=lib_svm.train(multi_cdf.cdfs_dist(obj.cdf,train_dat), train_grp, libsvm_opt_arg);
		end
	end

	methods
		function cl_res=classify(obj, test_dat)
			cl_res=obj.svm.classify(multi_cdf.cdfs_dist(obj.cdf,test_dat));
		end
	end
end