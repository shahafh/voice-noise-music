function vnm_examine_obs(base, db_type, alg)
	if isfield(alg.examine_obs,'make_cdf_pic')
		pict.make_pic=alg.examine_obs.make_cdf_pic;
	else
		pict.make_pic=false;
	end
	if isfield(alg.examine_obs,'make_cdf_fig')
		pict.make_fig=alg.examine_obs.make_cdf_fig;
	else
		pict.make_fig=false;
	end
	pict.make_pic_or_fig = pict.make_pic || pict.make_fig;

	if isfield(alg.examine_obs,'skip_existed')
		pict.skip_existed=alg.examine_obs.skip_existed;
	else
		pict.skip_existed=true;
	end
	
	% make output subdir name
	pict.root=[alg.examine_obs.out_dir filesep db_type];
	mkdir(pict.root);

	pict.obs_types=fieldnames(base(1).data{1});
	pict.obs_types(cellfun(@(x) not(isnumeric(base(1).data{1}.(x))), pict.obs_types))=[];
	pict.obs_types(strcmp('time', pict.obs_types))=[];
	pict.obs_types(strcmp('file_range', pict.obs_types))=[];

	%% make observation-channel list for parfor
	obs_ch_list=cellfun(@(x) size(base(1).data{1}.(x),2), pict.obs_types, 'UniformOutput',false);
	obs_name_ch_list=cell2mat(cellfun(@(x,y) cell2struct([repmat({x},y,1) num2cell((1:y)')], {'obs_name' 'obs_ch'}, 2) , pict.obs_types, obs_ch_list, 'UniformOutput',false));

	%% create output subfolders
	pict.obs_types=unique(regexprep(pict.obs_types,'^.*_',''));

	if pict.make_pic_or_fig
		for di=1:length(pict.obs_types)
			mkdir(pict.root, pict.obs_types{di});
		end

		fig_lin=figure('Visible','off');
		pict.palette=lines();
		close(fig_lin);
		pause(0.2);
		pict.fig_sz=get(0,'ScreenSize');
		pict.fig_sz(3)=pict.fig_sz(3)-10;
		pict.fig_sz(4)=pict.fig_sz(4)-130;
	end

	exam_log=cell(size(obs_name_ch_list));

	usepool = isfield(alg,'matlabpool');
	if usepool
		if matlabpool('size')>0
			matlabpool('close');
		end
		matlabpool(alg.matlabpool{:});
		spmd
			addpath_recursive(regexp(path(),'[^;]*','match','once'), 'ignore_dirs',{'\.svn' 'private' 'html' 'fspackage' 'FastICA' 'openEAR'});
			dos(['"' which('matlab_idle.bat') '"']);
		end
	end

	log_file_name=[pict.root filesep db_type '.txt'];
	if pict.skip_existed && exist(log_file_name,'file')
		[existed_log.rate,existed_log.name]=textread(log_file_name,'%n%s'); %#ok<REMFF1>
	else
		existed_log.rate=[];
		existed_log.name={};
		if exist(log_file_name,'file')
			delete(log_file_name);
		end
	end

	%% PARFOR removed due to lib_svm internal parallelisation
	fh_log=fopen(log_file_name,'a');
	for obs_name_ch_list_i=1:length(obs_name_ch_list)
		exam_obs=struct('name',obs_name_ch_list(obs_name_ch_list_i).obs_name, 'ch',obs_name_ch_list(obs_name_ch_list_i).obs_ch);
		existed_ind=find(strcmp([exam_obs.name num2str(exam_obs.ch)], existed_log.name),1);
		if isempty(existed_ind)
			exam_obs.rate=examine_one_obs_ch_case(base, exam_obs, pict, alg);
		else
			exam_obs.rate=existed_log.rate(existed_ind);
		end
		exam_log{obs_name_ch_list_i}=exam_obs;
		fprintf(fh_log, '%0.5f %s%d\n', exam_obs.rate, exam_obs.name, exam_obs.ch);
	end
	fclose(fh_log);

	if usepool
		matlabpool('close');
	end

	exam_log=cell2mat(exam_log);
	[~,si]=sort([exam_log.rate],'descend');
	exam_log=exam_log(si);

	fh_log=fopen(log_file_name,'w');
	arrayfun(@(x) fprintf(fh_log, '%0.5f %s%d\n', x.rate, x.name, x.ch), exam_log);
	fclose(fh_log);
end

function classifier_rate=examine_one_obs_ch_case(base, exam_obs, pict, alg)
	f_obs=cell(size(base));
	for cl_i=1:numel(base)
		f_obs{cl_i}=cellfun(@(x) x.(exam_obs.name)(:,exam_obs.ch), base(cl_i).data, 'UniformOutput',false);
	end

	obs_pic_subdir='';
	for pi=1:length(pict.obs_types)
		if not(isempty(regexp(exam_obs.name,pict.obs_types{pi},'once')))
			obs_pic_subdir=pict.obs_types{pi};
			break;
		end
	end

	out_img_dir=[pict.root filesep obs_pic_subdir];
	if pict.skip_existed
		ready_files=dir(out_img_dir);
		ready_files([ready_files.isdir])=[];
		ready_files={ready_files.name};
		ready_files=regexp(ready_files, ['^(?<rate>\d\.\d+) (?<name>' exam_obs.name ')(?<ch>' num2str(exam_obs.ch) ')\.(png|fig)$'], 'names');
		ready_files(cellfun(@isempty, ready_files))=[];
		if not(isempty(ready_files))
			classifier_rate=str2double(ready_files{1}.rate);
			return;
		end
	end

	if pict.make_pic_or_fig
		fig=figure('Units','pixels', 'Position',pict.fig_sz, 'Visible','off', 'PaperPositionMode','auto');

		fig_axes=zeros(2+numel(base),1);
		sp_rows=ceil(numel(base)/2)+1;
		for sp_i=0:1+numel(base)
			fig_axes(sp_i+1)=axes('Parent',fig, 'Units','normalized', 'Position', ...
				[0.05+rem(sp_i,2)*0.5, (sp_rows-1-fix(sp_i/2))/sp_rows+0.03, 0.44, 1/sp_rows-0.06]);
		end
	end

	x.qnt=0.05;
	x.rg=[inf -inf];

	%% Plot PDF & CDF
	cl_cdf=cell(size(f_obs));
	for cl_i=1:numel(f_obs)
		all_cur_cl_obs=cell2mat(f_obs{cl_i});

		if pict.make_pic_or_fig
			x.rg(1)=min(x.rg(1),quantile(all_cur_cl_obs,x.qnt));
			x.rg(2)=max(x.rg(2),quantile(all_cur_cl_obs,1-x.qnt));

			[hy,hx]=hist(all_cur_cl_obs,100);
			if ischar(base(cl_i).color)
				plot(fig_axes(1), hx,hy/sum(hy), base(cl_i).color);
			else
				plot(fig_axes(1), hx,hy/sum(hy), 'Color',base(cl_i).color);
			end
			hold(fig_axes(1), 'on');
		end

		files_cdx=quantile(all_cur_cl_obs,linspace(x.qnt,1-x.qnt,300))';
		files_cdf=zeros(1,numel(f_obs{cl_i}));

		for file_i=1:numel(f_obs{cl_i})
			file_obs=f_obs{cl_i}{file_i};

			if not(isempty(file_obs))
				cur_cdf=multi_cdf.fit(file_obs,{files_cdx});

				if pict.make_pic_or_fig
					cdf_x=(cur_cdf.cdfs.arg(1:end-1)+cur_cdf.cdfs.arg(2:end))/2;
					if ischar(base(cl_i).color)
						plot(fig_axes(2), cdf_x, cur_cdf.cdfs.cdf, base(cl_i).color);
					else
						plot(fig_axes(2), cdf_x, cur_cdf.cdfs.cdf, 'Color',base(cl_i).color);
					end
					hold(fig_axes(2), 'on');

					plot(fig_axes(2+cl_i), cdf_x, cur_cdf.cdfs.cdf, 'Color',pict.palette(randi(size(pict.palette,1),1),:));
					hold(fig_axes(2+cl_i), 'on');
				end

				files_cdf(1:size(cur_cdf.cdfs.cdf,1),file_i)=cur_cdf.cdfs.cdf;
			else
				fprintf('WARNING: no %s observations in file %s.\n',exam_obs.name,base(cl_i).data{file_i}.file_name);
			end
		end

		cl_cdf{cl_i}=multi_cdf();
		cl_cdf{cl_i}.cdfs.arg=files_cdx;
		cl_cdf{cl_i}.cdfs.cdf=median(files_cdf,2);
	end

	if pict.make_pic_or_fig
		hold(fig_axes(1), 'off');
		grid(fig_axes(1), 'on');
		ylim(fig_axes(1), [0 max(ylim(fig_axes(1)))]);
		if x.rg(1)<x.rg(2)
			xlim(fig_axes(1), x.rg);
		end
		ylabel(fig_axes(1), 'PDF');
		legend(fig_axes(1), {base.class}, 'Interpreter','none', 'Location','NW');
		legend(fig_axes(1), 'boxoff');
		titl=[exam_obs.name num2str(exam_obs.ch)];
		title(fig_axes(1), titl, 'interpreter','none');
	end

	%% Examine observations
	svm_cl_name=cell(numel(f_obs),1);
	svm_cl_dist=cell(numel(f_obs),1);

	for cl_i=1:numel(f_obs)
		if pict.make_pic_or_fig
			cdf_x=(cl_cdf{cl_i}.cdfs.arg(1:end-1)+cl_cdf{cl_i}.cdfs.arg(2:end))/2;
			if ischar(base(cl_i).color)
				plot(fig_axes(2), cdf_x, cl_cdf{cl_i}.cdfs.cdf, base(cl_i).color, 'LineWidth',5);
				plot(fig_axes(2), cdf_x, cl_cdf{cl_i}.cdfs.cdf, 'w', 'LineWidth',4);
				plot(fig_axes(2), cdf_x, cl_cdf{cl_i}.cdfs.cdf, [base(cl_i).color '--'], 'LineWidth',3);
			else
				plot(fig_axes(2), cdf_x, cl_cdf{cl_i}.cdfs.cdf, 'Color',base(cl_i).color, 'LineWidth',5);
				plot(fig_axes(2), cdf_x, cl_cdf{cl_i}.cdfs.cdf, 'w', 'LineWidth',4);
				plot(fig_axes(2), cdf_x, cl_cdf{cl_i}.cdfs.cdf, 'Color',base(cl_i).color, 'LineStyle','--', 'LineWidth',3);
			end

			if x.rg(1)<x.rg(2)
				xlim(fig_axes(2+cl_i), x.rg);
			end
			hold(fig_axes(2+cl_i), 'off');
			grid(fig_axes(2+cl_i), 'on');
			ylabel(fig_axes(2+cl_i), 'CDF');
			title(fig_axes(2+cl_i), base(cl_i).class, 'Interpreter','none');
		end

		svm_cl_name{cl_i}=zeros(numel(f_obs{cl_i}),1)+cl_i;
		svm_cl_dist{cl_i}=zeros(numel(f_obs{cl_i}),numel(cl_cdf));

		for file_i=1:numel(f_obs{cl_i})
			file_obs=f_obs{cl_i}{file_i};
			file_obs(isnan(file_obs))=[];
			if not(isempty(file_obs))
				for cl_cdf_i=1:numel(cl_cdf)
					svm_cl_dist{cl_i}(file_i,cl_cdf_i)=cl_cdf{cl_cdf_i}.distance(file_obs);
				end
			end
		end
	end

	svm_cl_name=cell2mat(svm_cl_name);
	svm_cl_dist=cell2mat(svm_cl_dist);

	svm_opt_arg = ' -h 0 -q';
	base_sz=arrayfun(@(x) numel(x.data), base);
	if alg.examine_obs.base_auto_balance
		svm_opt_arg = [svm_opt_arg cell2mat(arrayfun(@(x,y) sprintf(' -w%d %e',x,y), 1:numel(base_sz), min(base_sz)./base_sz', 'UniformOutput',false))];
	end

	[~,~,svm_cl_res]=lib_svm.find_cost_gamma(svm_cl_dist, svm_cl_name, svm_opt_arg);

	[rate_accuracy, rate_avr_recall] = lib_svm.rate_prediction(svm_cl_name, svm_cl_res);

	switch(alg.examine_obs.objective_func)
		case 'accuracy'
			svm_cl_rate = rate_accuracy;
		case 'average_recall'
			svm_cl_rate= rate_avr_recall;
		otherwise
			error('Unknown objectibe function.');
	end

	[classifier_rate, mi]=max(svm_cl_rate);

	if pict.make_pic_or_fig
		if x.rg(1)<x.rg(2)
			xlim(fig_axes(2), x.rg);
		end
		hold(fig_axes(2), 'off');
		grid(fig_axes(2), 'on');
		ylabel(fig_axes(2), 'CDF');
		title(fig_axes(2), ['cross-validation accuracy ' num2str(rate_accuracy(mi)) '; average recall ' num2str(rate_avr_recall(mi))], 'Interpreter','none');

		out_img_file_name=[out_img_dir filesep sprintf('%0.5f ',classifier_rate) titl];

		if pict.make_pic
			print(fig,'-dpng','-r96', [out_img_file_name '.png']);
		end

		% Сохранение исходной фигуры
		if pict.make_fig
			set(fig, 'Visible', 'on');
			saveas(fig, [out_img_file_name '.fig'], 'fig');
		end

		close(fig);
		pause(0.2);
	end
end
