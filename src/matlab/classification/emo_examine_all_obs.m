function vnm_examine_all_obs(pic)
	if nargin<1
%		pic.dirs={'berlin_anger_boredom'};
		pic.root='d:\w1';
		pic.dirs={	'berlin_anger_boredom'		'berlin_anger_boredom_female'		'berlin_anger_boredom_male'
					'berlin_anger_disgust'		'berlin_anger_disgust_female'		'berlin_anger_disgust_male'
					'berlin_anger_fear'			'berlin_anger_fear_female'			'berlin_anger_fear_male'
					'berlin_anger_happiness'	'berlin_anger_happiness_female'		'berlin_anger_happiness_male'
					'berlin_anger_sadness'		'berlin_anger_sadness_female'		'berlin_anger_sadness_male'
					'berlin_boredom_disgust'	'berlin_boredom_disgust_female'		'berlin_boredom_disgust_male'
					'berlin_boredom_fear'		'berlin_boredom_fear_female'		'berlin_boredom_fear_male'
					'berlin_boredom_happiness'	'berlin_boredom_happiness_female'	'berlin_boredom_happiness_male'
					'berlin_boredom_sadness'	'berlin_boredom_sadness_female'		'berlin_boredom_sadness_male'
					'berlin_disgust_fear'		'berlin_disgust_fear_female'		'berlin_disgust_fear_male'
					'berlin_disgust_happiness'	'berlin_disgust_happiness_female'	'berlin_disgust_happiness_male'
					'berlin_disgust_sadness'	'berlin_disgust_sadness_female'		'berlin_disgust_sadness_male'
					'berlin_fear_happiness'		'berlin_fear_happiness_female'		'berlin_fear_happiness_male'
					'berlin_fear_sadness'		'berlin_fear_sadness_female'		'berlin_fear_sadness_male'
					'berlin_happiness_sadness'	'berlin_happiness_sadness_female'	'berlin_happiness_sadness_male'
					'berlin_neutral_anger'		'berlin_neutral_anger_female'		'berlin_neutral_anger_male'
					'berlin_neutral_boredom'	'berlin_neutral_boredom_female'		'berlin_neutral_boredom_male'
					'berlin_neutral_disgust'	'berlin_neutral_disgust_female'		'berlin_neutral_disgust_male'
					'berlin_neutral_fear'		'berlin_neutral_fear_female'		'berlin_neutral_fear_male'
					'berlin_neutral_happiness'	'berlin_neutral_happiness_female'	'berlin_neutral_happiness_male'
					'berlin_neutral_sadness'	'berlin_neutral_sadness_female'		'berlin_neutral_sadness_male'};
%		pic.root='d:\Matlab work\vnm_pic\berlin_multiclass';
%			'berlin' 'berlin_03a' 'berlin_03b' 'berlin_08a' 'berlin_08b' 'berlin_09a' 'berlin_09b' 'berlin_10a' 'berlin_10b' 'berlin_11a' 'berlin_11b' ...
%			'berlin_12a' 'berlin_12b' 'berlin_13a' 'berlin_13b' 'berlin_14a' 'berlin_14b' 'berlin_15a' 'berlin_15b' 'berlin_16a' 'berlin_16b'};
		pic.func='mean';	% mean or prod
	end

%	pic.dirs=pic.dirs(:,3);

	pic.subdirs=dir([pic.root filesep pic.dirs{1}]);
	pic.subdirs(strcmp('.',{pic.subdirs.name}))=[];
	pic.subdirs(strcmp('..',{pic.subdirs.name}))=[];
	pic.subdirs(not([pic.subdirs.isdir]))=[];

	obs.rate=[];
	obs.name={};

	for sdi=1:numel(pic.subdirs)
		cur_files=dir([pic.root filesep pic.dirs{1} filesep pic.subdirs(sdi).name filesep '*.png']);
		for cfi=1:numel(cur_files)
			[~,obs_name]=strread(cur_files(cfi).name,'%f%s');
			obs_name=obs_name{1};
			obs_rate=zeros(numel(pic.dirs),1);
			for di=1:numel(pic.dirs)
				cur_file=dir([pic.root filesep pic.dirs{di} filesep pic.subdirs(sdi).name filesep '* ' obs_name]);
				if numel(cur_file)>1
					error('vnm_obs_sel:file_mask', 'Ambiguous file name mask');
				end
				obs_rate(di)=strread(cur_file(1).name,'%f',1);
			end
			obs.name{end+1,1}=obs_name;
			obs.rate(end+1,1)=feval(pic.func, obs_rate);
		end
	end

	[obs.rate,si]=sort(obs.rate,1,'descend');
	obs.name=obs.name(si);

	out_file_name=[pic.root filesep];
	if numel(pic.dirs)==1
		out_file_name=[out_file_name pic.dirs{1} filesep pic.dirs{1} '_'];
	end
	fid=fopen([out_file_name pic.func '.txt'],'w');
	for i=1:numel(obs.rate)
		fprintf(fid,'%0.4f %s\n',obs.rate(i),obs.name{i});
	end
	fclose(fid);
end
