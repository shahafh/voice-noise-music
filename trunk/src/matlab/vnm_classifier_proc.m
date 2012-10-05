function vnm_classifier_proc(base, db_type, alg)
	usepool = isfield(alg,'matlabpool') && not(isempty(alg.matlabpool)) && alg.classifier.proc.K_fold>1;
	if usepool
		if matlabpool('size')>0
			matlabpool('close');
		end
		if isa(alg.matlabpool,'char')
			alg.matlabpool={alg.matlabpool};
		end
		matlabpool(alg.matlabpool{:});
		spmd
			addpath_recursive(regexp(path(),'[^;]*','match','once'), 'ignore_dirs',{'\.svn' 'private' 'html' 'fspackage' 'FastICA' 'openEAR'});
			dos(['"' which('matlab_idle.bat') '"']);
		end
	end

	algs=lower(fieldnames(alg.classifier));
	algs(strcmp('proc',algs))=[];
	for a_i=1:numel(algs)

		cl_name=algs{a_i};

		classes_types=fieldnames(alg.classifier.proc.classes.(db_type));
		for classes_types_i=1:length(classes_types)
			cl_info=alg.classifier.proc.classes.(db_type).(classes_types{classes_types_i});
			classes=cl_info.classes;
			cl_alg=alg.classifier.(cl_name);

			cl_obs=cell(numel(classes),1);
			for cl_i=1:numel(classes)
				cur_obs=base(cl_i).data;

				if isfield(cl_info,'obs_expr') && not(isempty(cl_info.obs_expr))
					for fi=1:size(cur_obs,1)
						cur_obs{fi}=make_file_obs(cur_obs{fi}, cl_info.obs_expr); %#ok<AGROW>
					end
				end

				cl_obs{cl_i,1}=cur_obs;
			end

			train_info=struct('train_part',0.5, 'do_balance',false);
			if isfield(alg.classifier.proc,'train_part')
				train_info.train_part=alg.classifier.proc.train_part;
			end
			if isfield(alg.classifier.proc,'test_part')
				train_info.test_part=alg.classifier.proc.test_part;
			end
			if isfield(cl_alg,'train_set_balance')
				train_info.do_balance=cl_alg.train_set_balance;
			end

			cl_objs=cell(alg.classifier.proc.K_fold,1);
			cl_confs=cell(alg.classifier.proc.K_fold,1);
			cl_confs_raw=cell(alg.classifier.proc.K_fold,1);
			cl_rates=zeros(alg.classifier.proc.K_fold,1);

			if usepool
				parfor K=1:alg.classifier.proc.K_fold
					[cl_objs{K} cl_rates(K) cl_confs{K} cl_confs_raw{K}]=make_and_examine_classifier(classes, cl_obs, train_info, cl_name, cl_info, alg);
				end
			else
				for K=1:alg.classifier.proc.K_fold
					[cl_objs{K} cl_rates(K) cl_confs{K} cl_confs_raw{K}]=make_and_examine_classifier(classes, cl_obs, train_info, cl_name, cl_info, alg);
				end
			end

			[~,si]=sort(cl_rates);
			best_ind=si(round(length(si)/2));

			cl_best_rate=cl_rates(best_ind);
			cl_best_conf=cl_confs{best_ind};
			cl_best_obj=struct('info',struct('type',cl_name, 'name',classes_types{classes_types_i}, 'base_type',db_type, 'cl_info',cl_info, 'alg',alg), ...
								'obj',cl_objs{best_ind});

			save_classifier(cl_best_obj);

			fprintf('Worst RR - %f; Best RR - %f; Mean RR ~ %f; Median RR - %f\n', min(cl_rates), max(cl_rates), mean(cl_rates), cl_best_rate);

			disp(['Classifier ' db_type '.' classes_types{classes_types_i} '.' cl_name]);
			disp(['    Rate ' num2str(cl_best_rate)]);
			disp('    Confusion matrix');
			disp([{'' classes.name}; {classes.name}' num2cell(cl_best_conf)]);

			disp('');
			disp('    Raw confusion matrix');
			disp([{'' classes.name}; {classes.name}' num2cell(cl_confs_raw{best_ind})]);

			cl_confs_wa=zeros(size(cl_confs{1}));
			for K=1:alg.classifier.proc.K_fold
				cl_confs_wa=cl_confs_wa+cl_confs{K}*cl_rates(K);
			end
			cl_confs_wa=cl_confs_wa/sum(cl_rates);
			disp('');
			disp('    Weighted by rate average confusion matrix');
			disp([{'' classes.name}; {classes.name}' num2cell(cl_confs_wa)]);
		end
	end

	if usepool
		matlabpool('close');
	end
end

function y=make_file_obs(x, expr) %#ok<INUSL>
	y = cellfun(@(y) eval(y), expr, 'UniformOutput',false);
end

function save_classifier(classifier)
	if isfield(classifier.info.alg.classifier.proc,'save_path')
		cl_save_path=[classifier.info.alg.classifier.proc.save_path filesep];
	else
		cl_save_path='';
	end

	save([cl_save_path filesep 'vnm_' classifier.info.base_type '_' classifier.info.type '_' classifier.info.name '.mat'], 'classifier', '-v7.3');
end

function [cl_objs_K cl_rates_K cl_confs_K cl_confs_raw_K]=make_and_examine_classifier(classes, glob_cl_obs, train_info, cl_name, cl_info, alg)
	cl_sz=cellfun(@length, glob_cl_obs);

	%% prepare train and test sets
	% define train and test set sizes
	if train_info.do_balance
		train_sz=repmat(round(min(cl_sz)*train_info.train_part), length(classes), 1);
	else
		train_sz=round(cl_sz*train_info.train_part);
	end
	if isfield(train_info,'test_part')
		test_sz=round(cl_sz*train_info.test_part);
	else
		test_sz=cl_sz-train_sz;
	end

	train_sz_sum=[0; cumsum(train_sz)];
	test_sz_sum =[0; cumsum(test_sz)];

	% generate train and test sets from class observations with spesified size
	train_dat=cell(sum(train_sz),1);		train_grp=cell(size(train_dat));
	test_dat =cell(sum(test_sz),1);			test_grp =cell(size(test_dat));

	for cl_i=1:length(cl_sz)
		rnd_ind=randperm(cl_sz(cl_i));

		train_src_ind=rnd_ind(1:train_sz(cl_i));					train_dst_ind=train_sz_sum(cl_i)+1:train_sz_sum(cl_i+1);
		test_src_ind=rnd_ind(cl_sz(cl_i)-(test_sz(cl_i)-1:-1:0));	test_dst_ind =test_sz_sum(cl_i)+1 :test_sz_sum(cl_i+1); 

		train_dat(train_dst_ind)=glob_cl_obs{cl_i}(train_src_ind);		train_grp(train_dst_ind)={classes(cl_i).name};
		test_dat(test_dst_ind)=  glob_cl_obs{cl_i}(test_src_ind);		test_grp(test_dst_ind)=  {classes(cl_i).name};
	end

	% randomize data order in train and test sets
	rnd_ind=randperm(length(train_dat));	train_dat=train_dat(rnd_ind);	train_grp=train_grp(rnd_ind);
	rnd_ind=randperm(length(test_dat));		test_dat=test_dat(rnd_ind);		test_grp=test_grp(rnd_ind);

	%% make some common and useful data for classifiers from train data set
	% make class observation form train set
	etc_data=make_etc_data(train_dat, train_grp, {classes.name}, cl_info);

	cl_objs_K=feval(['vnm_classifier_' cl_name '.train'], train_dat, train_grp, etc_data, alg.classifier.(cl_name));
	cl_out=cl_objs_K.classify(test_dat);
	[cl_rates_K cl_confs_K cl_confs_raw_K]=classify_rate({classes.name}, test_grp, cl_out);
end

function etc_data=make_etc_data(train_dat, train_grp, classes, cl_info)
	etc_data.cl_name=classes(:);

	etc_data.cl_obs=cell(size(etc_data.cl_name));
	for i=1:length(etc_data.cl_obs)
		etc_data.cl_obs{i}=train_dat(strcmp(train_grp,etc_data.cl_name{i}),:);
	end

	% make median cdf's for train data
	if isfield(cl_info,'obs_expr') && not(isempty(cl_info.obs_expr))
		etc_data.cl_cdf=cell(size(etc_data.cl_obs,1),1);
		for cl_i=1:size(etc_data.cl_obs,1)
			all_cl_obs=vertcat(etc_data.cl_obs{cl_i,1}{:});
			cl_obs_arg=cell(1,size(all_cl_obs,2));
			for obs_i=1:length(cl_obs_arg)
				cl_obs_arg{obs_i}=quantile(cell2mat(all_cl_obs(:,obs_i)), linspace(0.05,0.95,250)');
			end
			files_cdf=cell(length(cl_obs_arg),1);
			for obs_i=1:length(files_cdf)
				files_cdf{obs_i}=zeros(length(cl_obs_arg{obs_i})-1, length(etc_data.cl_obs{cl_i,1}));
			end

			for file_i=1:length(etc_data.cl_obs{cl_i,1})
				file_obj=multi_cdf.fit(etc_data.cl_obs{cl_i,1}{file_i}, cl_obs_arg);
				for obs_i=1:length(files_cdf)
					files_cdf{obs_i}(:,file_i)=file_obj.cdfs(obs_i).cdf;
				end
			end

			etc_data.cl_cdf{cl_i}=file_obj;
			for obs_i=1:length(files_cdf)
				etc_data.cl_cdf{cl_i}.cdfs(obs_i).cdf=median(files_cdf{obs_i},2);
			end
		end
	end
end

function [cl_rate cl_conf cl_conf_raw]=classify_rate(class_name, test_grp, cl_res)
	cl_conf_raw=confusionmat(test_grp, cl_res, 'order',class_name);
	cl_conf=cl_conf_raw;
	for i=1:size(cl_conf,1)
		cl_conf(i,:)=cl_conf(i,:)/(sum(cl_conf(i,:))+realmin('double'));
	end
	cl_rate=mean(diag(cl_conf));
end
