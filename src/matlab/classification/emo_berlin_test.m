function vnm_berlin_test(db_dir)
%{
	if nargin<1
		db_dir='\\192.168.21.235\bases$\Other\Emotion\Berlin\wav\';
	end

	db_list=dir([db_dir '*.wav']);
	db_list(1).est=0;

	parfor i=1:length(db_list)
		[f0_val, ~, f0_belief]=f0_track('file',[db_dir db_list(i).name], 'f0_range',[60 800], 'vocal_thresh',0.5, 'vocal_reg_sz',[0.020 0.030], 'dt0_max',0.10, 't0_filter_delay',0);
		f0_val(not(f0_belief))=[];

%		info.f0.val=info.f0.val/median(info.f0.val);
		fr=vnm_fractile(f0_val, [0.25 0.5 0.75]);
		db_list(i).est=(fr(3)-fr(2)) - (fr(2)-fr(1));
	end

	save('vnm_berlin_test.mat','db_list');
%}
	load('vnm_berlin_test.mat','db_list');

	vnm_map=containers.Map;
	for i=1:length(db_list)
		key=db_list(i).name(6);
		if isKey(vnm_map,key)
			vnm_map(key)=[vnm_map(key) db_list(i).est];
		else
			vnm_map(key)=db_list(i).est;
		end
	end

	figure('Name','Berlind DB Emotions', 'NumberTitle','off', 'Units','pixels', 'Position',get(0,'ScreenSize'));
	traces={'r','g','b','c','m','k','y'};
	leg=keys(vnm_map);
	leg_out={};
	for i=1:length(leg)
		if not(any(strcmp(leg{i},{'A','N'})))
			continue;
		end
		leg_out{end+1}=leg{i};
		vals=vnm_map(leg{i});
		[hY,hX]=hist(vals,20);
		hY=hY/length(vals);
		disp(length(vals));
%		cur_x=sort(data(i).f0.val);
%		cur_y=(0:length(cur_x)-1)/(length(cur_x)-1);
		plot(hX, hY, traces{rem(i-1,length(traces))+1});
		hold on;
%		leg{i}=sprintf('%s %.3f', data(i).name, data(i).est.fract);
	end
	hold off;
	grid on;
	legend(leg_out,'Location','NW','Interpreter','none');
	legend('boxoff');
end
