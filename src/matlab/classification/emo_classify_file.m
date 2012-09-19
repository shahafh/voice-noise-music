function vnm_classify_file(in_wav_file, in_classifier_file)
	%% function input arguments
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Select file for processing');
		if dlg_name==0
			return;
		end
		in_wav_file=fullfile(dlg_path,dlg_name);
	end

	if nargin<2
		[dlg_name,dlg_path]=uigetfile({'*.mat','MATLAB files (*.mat)'},'Select classifier file');
		if dlg_name==0
			return;
		end
		in_classifier_file=fullfile(dlg_path,dlg_name);
	end
	cfg=struct('wav_file',in_wav_file, 'classifier_file',in_classifier_file);

	pause(0.2);


	%% prepare classifier
	loaded_info=load(cfg.classifier_file);
	if isfield(loaded_info.classifier.info.alg.obs_general, 'snr')
		loaded_info.classifier.info.alg.obs_general=rmfield(loaded_info.classifier.info.alg.obs_general, 'snr');
	end
	if isfield(loaded_info.classifier.info.alg.obs_general, 'rand_ampl')
		loaded_info.classifier.info.alg.obs_general=rmfield(loaded_info.classifier.info.alg.obs_general, 'rand_ampl');
	end

	alg=loaded_info.classifier.info.alg;
	cl_info=loaded_info.classifier.info.cl_info;

	%% prepare observations
	cur_base={'test_file' vnm_parse_files({struct('file_name',cfg.wav_file)}, alg)};
	if isfield(alg,'meta_obs')
		for ai=1:length(alg.meta_obs)
			cur_base=feval(['vnm_meta_' alg.meta_obs(ai).type], cur_base, alg.meta_obs(ai).params, alg);
		end
	end
	if isempty(cur_base(1).data) % file can be removed by VAD or ISNAN
		return;
	end
%{
	obs=cur_base(1).data{1};
	obs_list=fieldnames(obs);
	for oi=1:length(obs_list)
		save_var=obs.(obs_list{oi});
		save(['mtlb_frame_obs_' obs_list{oi} '.txt'],'save_var','-ascii');
	end
%}
	if isfield(cl_info,'obs_expr')
		test_dat={make_file_obs(cur_base(1).data{1}, cl_info.obs_expr)};
	else
		test_dat=cur_base(1).data;
	end

	%% estimate emotion state
	cl_res=loaded_info.classifier.obj.classify(test_dat);

	fprintf('File %s have been classified as %s.\n', cfg.wav_file, cl_res{1});

	%% display classification results
%	plot_result(cur_x, alg, cfg, cl);
end

function y=make_file_obs(x, expr) %#ok<INUSL>
	y = cellfun(@(y) eval(y), expr, 'UniformOutput',false);
end

%{
%% Old signal display function. Can be useful in future
function plot_result(x, alg, cfg, cl)
	fig=figure('Name','Stress classification', 'NumberTitle','off', 'Toolbar','figure', ...
		'Units','normalized', 'Position',[0 0 1 1], 'WindowButtonDownFcn', @OnMouseClick);
	sub_plot1=subplot(2,1,1, 'Units','normalized');
	plot((0:size(x,1)-1)/alg.obs.general.fs, x);
	x_lim=[0 (size(x,1)-1)/alg.obs.general.fs];
	axis([x_lim max(abs(x))*1.1*[-1 1]]);
	grid on;
	xlabel('Time, sec');
	ylabel('Input signal');
	caret(1)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);
	stat_line(1,1)=line([0 0], ylim(), 'Color','k', 'LineWidth',1.5);
	stat_line(1,2)=line([0 0], ylim(), 'Color','m', 'LineWidth',2);
	stat_line(1,3)=line([0 0], ylim(), 'Color','k', 'LineWidth',1.5);

	subplot(2,1,2);
	plot(cl.time(:,2), cl.res, 'bd-');
	line(x_lim, [0.5 0.5], 'Color','r');
	axis([x_lim -0.2 length(cl.names)-1+0.2]);
	grid('on');
	xlabel('Time, sec');
	ylabel('Classification');
	for i=1:length(cl.names)
		text(0.1, i-1+0.1, cl.names{i}, 'Interpreter','None', 'BackgroundColor','w', 'EdgeColor','k');
	end
	caret(2)=line([0 0], ylim(), 'Color','r', 'LineWidth',2);
	stat_line(2,1)=line([0 0], ylim(), 'Color','k', 'LineWidth',1.5);
	stat_line(2,2)=line([0 0], ylim(), 'Color','m', 'LineWidth',2);
	stat_line(2,3)=line([0 0], ylim(), 'Color','k', 'LineWidth',1.5);

	title([	'wav_file: "' cfg.wav_file '"; stat_delay: ' num2str(cfg.stat_delay) ' sec. (' num2str(cfg.stat_delay_fr)	...
			' frames); stat_step: ' num2str(cfg.stat_step*100) '% (' num2str(cfg.stat_step_fr) ' frames); '			...
			' classifier_file: "' cfg.classifier_file '"'], 'Interpreter','None');

	ctrl_pos=get(sub_plot1,'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
		'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @OnPlaySignal);

	set(zoom,'ActionPostCallback',@OnZoomPan);
	set(pan ,'ActionPostCallback',@OnZoomPan);
	zoom xon;
	set(pan, 'Motion', 'horizontal');

	player = audioplayer(x, alg.obs.general.fs);
	set(player, 'StartFcn',@CallbackPlay, 'StopFcn',@CallbackPlayStop, ...
				'TimerFcn',@CallbackPlay, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	data = guihandles(fig);
	data.user_data = struct('player',player, 'btn_play',btn_play, 'stat_line',stat_line, 'cl',cl);
	guidata(fig,data);
end

function OnPlaySignal(hObject, eventdata)
	data = guidata(hObject);
	if not(isplaying(data.user_data.player))
		x_lim=min(data.user_data.player.TotalSamples,max(1,round( xlim()*data.user_data.player.SampleRate+1 )));
		play(data.user_data.player, x_lim);
		set(data.user_data.btn_play, 'String', 'Stop playing');
	else
		stop(data.user_data.player);
	end
end

function CallbackPlay(obj, event, string_arg)
	user_data=get(obj, 'UserData');
	cur_pos=(get(obj, 'CurrentSample')-1)/get(obj, 'SampleRate');
	for i=1:length(user_data.caret)
		set(user_data.caret(i),'XData',[cur_pos cur_pos]);
	end
end

function CallbackPlayStop(obj, event, string_arg)
	CallbackPlay(obj);
	user_data=get(obj, 'UserData');
	set(user_data.btn_play, 'String', 'Play view');
end

function OnZoomPan(hObject, eventdata)
	data = guidata(hObject);
	x_len= data.user_data.player.TotalSamples/data.user_data.player.SampleRate;

	x_lim=xlim();
	rg=x_lim(2)-x_lim(1);
	if x_lim(1)<0
		x_lim=[0 rg];
	end
	if x_lim(2)>x_len
		x_lim=[max(0, x_len-rg) x_len];
	end

	child=get(hObject,'Children');
	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
end

function OnMouseClick(hObject, eventdata)
	%% get click position in current axes coordinates
	axes_obj = get(hObject, 'CurrentAxes');
	axes_pos = get(axes_obj, 'Position');
	mouse_pos = get(hObject, 'CurrentPoint');

	if  mouse_pos(1)<axes_pos(1) || mouse_pos(1)>axes_pos(1)+axes_pos(3) || ...
		mouse_pos(2)<axes_pos(2) || mouse_pos(2)>axes_pos(2)+axes_pos(4)
		return;
	end
	
	mouse_pos=(mouse_pos-axes_pos([1 2]))./axes_pos([3 4]);
	axes_xlim = get(axes_obj, 'XLim');
	axes_ylim = get(axes_obj, 'YLim');
	mouse_pos=[diff(axes_xlim) diff(axes_ylim)].*mouse_pos+[axes_xlim(1) axes_ylim(1)];

	%% process click
	data = guidata(hObject);
	[~,mi]=min(abs(data.user_data.cl.time(:,2)-mouse_pos(1)));
	for i=1:size(data.user_data.stat_line,2)
		set(data.user_data.stat_line(:,i), 'XData', data.user_data.cl.time(mi,i)+[0 0]);
	end
end
%}