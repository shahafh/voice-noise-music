function vnm_classify_base(cl_path, base_path, base_type, output_file, mtlb_pool)
	%% input parameters
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.mat','MATLAB files (*.mat)'},'Select classifier file');
		pause(0.2);
		if dlg_name==0
			return;
		end
		cl_path=fullfile(dlg_path,dlg_name);
	end

	if nargin<2
		base_path=uigetdir('','Select base path');
		pause(0.2);
		if base_path==0
			return;
		end
	end
	if nargin<3
		bases_list={'berlin' 'st' 'telecom'};
		l_ind=listdlg('ListString',bases_list, 'SelectionMode','single', 'Name','Select base type', 'ListSize',[160 100]);
		pause(0.2);
		if isempty(l_ind)
			return;
		end
		base_type=bases_list{l_ind};
	end
	if nargin<4
		output_file='';
	end
	if nargin<5
		mtlb_pool='';
	end


	%% prepare classifier
	loaded_info=load(cl_path);
	if isfield(loaded_info.classifier.info.alg.obs.general, 'snr')
		loaded_info.classifier.info.alg.obs.general=rmfield(loaded_info.classifier.info.alg.obs.general, 'snr');
	end
	if isfield(loaded_info.classifier.info.alg.obs.general, 'rand_ampl')
		loaded_info.classifier.info.alg.obs.general=rmfield(loaded_info.classifier.info.alg.obs.general, 'rand_ampl');
	end

	alg=loaded_info.classifier.info.alg;
	cl_type=loaded_info.classifier.info.type;

	cl_info=loaded_info.classifier.info.cl_info;
	classes=cl_info.classes;
	cl_names={classes.name};

	alg.obs.general.skip_parsing=true;
	base=feval(['vnm_parse_' base_type], base_path, alg);


	%% make {file_name class_name} pairs
	files_cl_data=cell(0,1);
	files_cl_type=cell(0,1);
	for cl_i=1:numel(classes)
		cur_cl=classes(cl_i);
		base_ind=false(size(base));
		for cl_be_i=1:numel(cur_cl.base_el)
			base_ind = base_ind | strcmp(cur_cl.base_el{cl_be_i}, base(:,1));
		end
		cur_base=base(base_ind,2);
		cur_base=vertcat(cur_base{:});
		cur_cl=repmat({cur_cl.name}, size(cur_base,1), 1);

		out_ind=size(files_cl_data,1)+(1:size(cur_base,1));
		files_cl_data(out_ind)=cur_base;
		files_cl_type(out_ind)=cur_cl;
	end



	%% classify all_pairs
	alg.obs.general=rmfield(alg.obs.general,'skip_parsing');
	
	if not(isempty(mtlb_pool))
		if matlabpool('size')>0
			matlabpool('close');
		end
		if isa(mtlb_pool,'char')
			mtlb_pool={mtlb_pool};
		end
		matlabpool(mtlb_pool{:});
	end
	spmd
		addpath_recursive(regexp(path(),'[^;]*','match','once'), 'ignore_dirs',{'\.svn','html'});
		dos(['"' which('matlab_idle.bat') '"']);
	end

	if isfield(cl_info,'obs_expr')
		par_obs_expr=cl_info.obs_expr;
	else
		par_obs_expr='';
	end
	par_cl_obj=loaded_info.classifier.obj;

	files_cl_res=cell(size(files_cl_data,1),1);
	file_log=cell(size(files_cl_data,1),1);
	parfor fi=1:size(files_cl_data,1) %parfor
		cur_base=[files_cl_type(fi) {vnm_parse_files(files_cl_data(fi), alg)}];
		if isfield(alg,'meta_obs')
			algs=lower(fieldnames(alg.meta_obs));
			for ai=1:length(algs)
				cur_base=feval(['vnm_meta_' algs{ai}], cur_base, alg);
			end
		end
		if isempty(cur_base(1).data) % file can be removed by VAD or ISNAN
			continue;
		end

		if not(isempty(par_obs_expr))
			test_dat={make_file_obs(cur_base(1).data{1}, par_obs_expr)};
		else
			test_dat=cur_base(1).data;
		end

		files_cl_res(fi)=par_cl_obj.classify(test_dat);

		if not(isequal(files_cl_type{fi},files_cl_res{fi}))
			file_log{fi}=sprintf('%s; %s estimated as %s', files_cl_data{fi}.file_name, cur_base{1}, files_cl_res{fi});
 			disp(file_log{fi});
		end
	end
	if not(isempty(mtlb_pool))
		matlabpool('close');
	end


	%% create log file
	if not(isempty(output_file))
		log_fh=fopen(output_file,'w');
		if log_fh==-1
			error('emo:classify_base','Can''t open log file for write.');
		end
		fprintf(log_fh,'cl_type = %s\n',cl_type);
		fprintf(log_fh,'cl_path = %s\n',cl_path);
		fprintf(log_fh,'base_path = %s\n',base_path);
		fprintf(log_fh,'base_type = %s\n',base_type);
	end


	%% Process unclassified files
	cut_ind=cellfun(@isempty, files_cl_res);
	if any(cut_ind)
		disp('Some files was unclassified (possible rejected by VAD or ISNAN):');
		cellfun(@(x) fprintf('   %s\n',x.file_name), files_cl_data(cut_ind));

		fprintf(log_fh,'Some files was unclassified (possible rejected by VAD or ISNAN):\n');
		cellfun(@(x) fprintf(log_fh,'   %s\n',x.file_name), files_cl_data(cut_ind));

		files_cl_data(cut_ind)=[];
		files_cl_type(cut_ind)=[];
		files_cl_res(cut_ind)=[];
	end


	%% Display result
	cl_conf_raw=confusionmat(files_cl_type,files_cl_res, 'order',cl_names);
	cl_conf=cl_conf_raw;
	for i=1:size(cl_conf,1)
		cl_conf(i,:)=cl_conf(i,:)/(sum(cl_conf(i,:))+realmin('double'));
	end
	cl_rate=mean(diag(cl_conf));

	disp([cl_path ' classifier']);
	disp(['    Rate ' num2str(cl_rate)]);
	disp( '    Confusion matrix');
	disp([cl_names(:) num2cell([cl_conf cl_conf_raw])]);

	if not(isempty(output_file))
		file_log(cellfun(@isempty, file_log))=[];
		cellfun(@(x) fprintf(log_fh,'%s\n',x), file_log);
		fprintf(log_fh, '    Rate - %0.4f\n',cl_rate);
		fprintf(log_fh, '    Confusion matrix\n');
		spc=repmat(' ',length(cl_names),3);
		conf_out=[char(cl_names{:}) spc num2str(cl_conf,'%9.4f') spc num2str(cl_conf_raw,'%6d')];
		conf_out=mat2cell(conf_out, ones(length(cl_names),1),size(conf_out,2));
		cellfun(@(x) fprintf(log_fh,'%s\n',x), conf_out);
		fclose(log_fh);
	end
end

function y=make_file_obs(x, expr) %#ok<INUSL,STOUT>
	evalc(expr);
end
