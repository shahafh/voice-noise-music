function [factor_nam, factor_val]=vnm_examine_class_sep(base_name, fn)

	tic
	load(['vnm_cache_' base_name '_meta.mat']);
	toc
	
	%% Make list of appropriate observations
	tic
	obs=base(1).data{1};
	fld_names = fieldnames(obs);
	fld_names(strcmp('time', fld_names)) = [];
	fld_names(strcmp('file_range', fld_names)) = [];
	fld_names(cellfun(@(x) size(obs.(x),1)~=size(obs.time,1), fld_names))=[];

	%% Make unrolled observation-channel list
	obs_name_ch=num2cell(cellfun(@(x) size(obs.(x),2), fld_names));
 	obs_names=cellfun(@(x,y) cellfun(@(x1) sprintf('x.%s(:,%d)',x,x1), num2cell(1:y), 'UniformOutput',false), fld_names, obs_name_ch, 'UniformOutput',false);
 	obs_names=[obs_names{:}];
	toc

	%% Collect per class function prepared observations
	tic
	vnm_sz = length(base);
	obs_stats = cell(vnm_sz,1);
	for vnm_i=1:vnm_sz
		file_sz = numel(base(vnm_i).data);
		obs_stats{vnm_i} = inf(file_sz, length(obs_names));
		for file_i=1:file_sz
			obs=base(vnm_i).data{file_i};
			p = 0;
			for obs_i=1:length(fld_names)
				x = obs.(fld_names{obs_i});
				obs_stats{vnm_i}(file_i, p+(1:size(x,2))) = feval(fn,x);
				p = p+size(x,2);
			end
		end
	end
	toc

	%% Calculate F-measure
	tic
	obs_stats_all = cell2mat(obs_stats);
	var_div = zeros(vnm_sz+1, length(obs_names));
	for vnm_i=1:vnm_sz
		var_div(vnm_i, :) = var(obs_stats{vnm_i})./var(obs_stats_all);
	end
	var_div(vnm_sz+1,:) = mean(var_div(1:vnm_i, :));
	
	%% Select best F-measured observations
	[factor_val, i] = sort(var_div(vnm_sz+1,:));
	factor_nam = obs_names(i)';
	factor_val = factor_val';
	toc
end
