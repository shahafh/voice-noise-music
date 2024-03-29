function base=vnm_meta_openear(base, alg, algs) %#ok<INUSD>
	[base_root]=fileparts(base(1).data{1}.file_name);
	openear_base=load_openear_base(base_root, alg);
	base = merge_base ( base, openear_base );
end

function [ openEAR ] = load_openear_base( base_root, alg )
	out_file = alg.filename;
	if exist([base_root filesep out_file '.mat'],'file') % just load precalculated observations
		disp('.mat file found. Loading, please wait...');
		load([base_root filesep out_file '.mat']);
		return;
	end
	if exist([base_root filesep out_file '.arff'],'file') % load precalculated observations from openEAR .arff file
		disp('.arff file found. Loading, please wait...');
		openEAR=load_arff([base_root filesep out_file '.arff']);
		save([base_root filesep out_file '.mat'], 'openEAR');
		disp('openEAR database .mat file save complete');
		return;
	end
	% No cached observations. Recalculate it
	disp('No cached observations. Recalculating database...');
	buildarff( base_root, 'vnmbase', alg );
	disp('.arff file building complete');
	openEAR=load_arff([base_root filesep out_file '.arff']);
	save([base_root filesep out_file '.mat'], 'openEAR');
	disp('openEAR database .mat file save complete');
end
	
%####################################
%# Loads .arff generated by openEAR #
%####################################
function [ openEAR ] = load_arff( file_path )
	fid = fopen(file_path);
	str = '';
	openEAR.attr = {};

	while ~strcmp(str, '@data')
		str = fgetl(fid);
		if ~strcmp(str,'')
			s = regexp(str, '\s+', 'split');
			if strcmp(s(1), '@attribute')
				openEAR.attr=[openEAR.attr; s(2:3)];
			end;
		end;
	end;
	classes = regexp(openEAR.attr{end,2}(2:end-1),',','split')';
	openEAR.base=classes;

	fgetl(fid);
	while ~feof(fid)
		str=fgetl(fid);
		tmp=regexp(str,',','split');
		for ii=2:size(tmp,2)-1
			tmp{1,ii}=str2num(tmp{1,ii}); %#ok<ST2NM>
		end
		k=find(strcmp(classes,tmp{end}),1);
		if size(openEAR.base,2)==1
			openEAR.base(k).data{1}=struct('file_name', tmp{1}(2:end-1), 'openEAR', {tmp(2:end-1)});
		else
			openEAR.base(k).data{end+1,1}=struct('file_name', tmp{1}(2:end-1), 'openEAR', {tmp(2:end-1)});
		end
	end
	fclose(fid);
end

%####################################
%#Calls openEAR and generates *.arff#
%####################################
function buildarff( db_path, cfg_file, alg )
	
	out_file = alg.filename;
	EAR_path = [fileparts(which(mfilename)) filesep alg.EAR_path];
	cl_names = alg.cl_names;

	if strcmp(cl_names, 'folders')  % each class placed in the separate folder
		disp('Collecting classnames and data from folders...');
		lst=finddirs(db_path);
		class_string=[];
		classes={};
		for k=1:length(lst)
			[~,classes{end+1}]=fileparts(lst{k}); %#ok<AGROW>
			class_string=[class_string ',' classes{end}]; %#ok<AGROW>
		end
		class_string(1)='';
		for k=1:length(lst)
			lst{k}=findfiles(lst{k}, '*.wav');
		end
	elseif strcmp(cl_names, 'file_mask')  % classnames are given in the .cfg file, files should be separated by file mask
		disp('Collecting data from files...');
		alg_classes = alg.classes;
		classes = alg_classes(:,1)';
		class_string=sprintf(',%s',classes{:});
		class_string(1)=[];
		lst=alg_classes(:,2)';
		for k=1:length(lst)
			mask=lst{k};
			lst{k}=dir(db_path);
			lst{k}([lst{k}.isdir])=[];
			lst{k}={lst{k}.name};
			db_mask=regexp(lst{k}, mask);
			lst{k}(cellfun(@isempty, db_mask))=[];
			lst{k}=strcat([db_path filesep],lst{k});
		end
	end

	disp('Generating .arff file.');

	for k=1:length(lst)
		MaxNum = length(lst{k});
		h=waitbar(0,['Group ' classes{k} ' (' int2str(k) '/' int2str(length(lst)) '); Total: ' int2str(MaxNum) ' files']);
		for i=1:MaxNum
			cmd=['"' EAR_path filesep 'windows_bin' filesep 'SMILExtract.exe" -C "' EAR_path filesep 'config' filesep cfg_file '.conf" -I "\\' lst{k}{i}...
				'" -O "' db_path filesep out_file '.arff" -instname "' lst{k}{i} '" -classes {' class_string '} -classlabel ' classes{k} ' -corpus "' db_path '"'];
			[dos_status, dos_result]=dos(cmd);
			if dos_status~=0
				disp('Output:');
				disp(dos_result);
			end
			waitbar(i/MaxNum,h);
		end
		close(h);
	end

end

function dir_list=finddirs(root)
    dir_list={};
    dir_res=dir(root);
    for i=1:length(dir_res) %#ok<*ALIGN>
        if dir_res(i).isdir
			dir_list{end+1}=[root filesep dir_res(i).name]; %#ok<AGROW>
		end
	end
	dir_list=dir_list(~(strcmp(dir_list, [root filesep '.'])|strcmp(dir_list, [root filesep '..'])));
end

%####################################
%#       Merge databases            #
%####################################
function base=merge_base(base, openEAR)
%	disp('Merging databases...');
	for k=1:size(base,1)
		c=strcmpi(openEAR.base(:,1), base(k,1));
		[~,ear_cur_fn]=cellfun(@(x) fileparts(x.file_name), openEAR.base(c).data, 'UniformOutput',false);
		for i=1:size(base(k).data,1)
			[~,cur_fn]=fileparts(base(k).data{i}.file_name);
			base(k).data{i}.openear=[openEAR.base(c).data{strcmp(ear_cur_fn, cur_fn)}.openEAR{:}];
		end
	end
end
