function control_motor_gui_dark_full_v2_7
% =========================================================================
% Interfaz Gráfica de Usuario (GUI) para Control de Motor en Simulink
% Versión: 2.7 (Layout del Panel TCP Corregido)
% MATLAB: R2025a
%
% Funcionalidades:
% - ... (las mismas que antes)
% =========================================================================

% -------------------------------------------------------------------------
% 1. CONFIGURACIÓN INICIAL Y VARIABLES DE ESTADO
% -------------------------------------------------------------------------
S.mdl = 'General_3'; % <<<< Nombre de tu modelo
S.t = []; S.y = []; S.r = []; % Datos para la gráfica
S.t0 = []; % Temporizador para el tiempo de simulación
S.tcp.client = []; % Objeto del cliente TCP
S.tcp.senderTimer = []; % Timer para el envío de datos
% Límites para el slider/potenciómetro de w_cmd
S.slider.min = 0;
S.slider.max = 1300;
% Paleta de colores para el tema oscuro
C.bg = [0.12 0.12 0.12]; C.panel = [0.18 0.18 0.18]; C.text = [0.9 0.9 0.9];
C.edit_bg = [0.25 0.25 0.25]; C.btn_run = [0.1 0.5 0.2]; C.btn_stop = [0.7 0.2 0.2];
C.btn_util = [0.3 0.3 0.3]; C.grid = [0.4 0.4 0.4]; C.plot_ref = [0.2 0.7 1.0];
C.plot_meas = [1.0 0.4 0.4];
% Asegurar que TODAS las variables necesarias existan en el workspace base
ensure('w_cmd', 0);
ensure('Td', 2.0);
ensure('enable_shape', 1);
%ensure('R_vec', [1, 0, 0, 0, 0, 0]);
ensure('R_vec', [21, 35, 15, 0, 0, 0]);
ensure('use_pid', 1);
ensure('Kp', 246.285);
ensure('Ki', 1.71089);
ensure('Kd', -2.44598);
% Cargar modelo de Simulink
try
    if ~bdIsLoaded(S.mdl), load_system(S.mdl); end
    set_param(S.mdl, 'SimulationMode', 'normal', 'StopTime', 'inf');
catch ME
    errordlg(['No se pudo cargar el modelo: ', S.mdl, '. Error: ', ME.message], 'Error');
    return;
end
% -------------------------------------------------------------------------
% 2. CONSTRUCCIÓN DE LA INTERFAZ GRÁFICA
% -------------------------------------------------------------------------
H = struct(); % Estructura para almacenar los handles
H.f = figure('Name', 'Motor Control GUI (Full) - v2.7', 'NumberTitle', 'off', 'MenuBar', 'none', 'Color', C.bg, 'DefaultUicontrolFontName', 'Segoe UI', 'DefaultUicontrolFontSize', 10, 'CloseRequestFcn', @onClose);
% --- Paneles de Control (Layout ajustado para TCP) ---
panelTop = uipanel(H.f, 'Title', 'CONTROL DE SIMULACIÓN', 'FontSize', 10, 'BackgroundColor', C.panel, 'ForegroundColor', C.text, 'Position', [0.01 0.88 0.98 0.11]);
panelLeftMode = uipanel(H.f, 'Title', 'MODO DE CONTROL', 'FontSize', 10, 'BackgroundColor', C.panel, 'ForegroundColor', C.text, 'Position', [0.01 0.68 0.30 0.19]);
panelLeftRef = uipanel(H.f, 'Title', 'CONTROL DE REFERENCIA', 'FontSize', 10, 'BackgroundColor', C.panel, 'ForegroundColor', C.text, 'Position', [0.01 0.36 0.30 0.31]);
panelTCP = uipanel(H.f, 'Title', 'CONEXIÓN EXTERNA (TCP)', 'FontSize', 10, 'BackgroundColor', C.panel, 'ForegroundColor', C.text, 'Position', [0.01 0.05 0.30 0.30]);
% --- Componentes en Panel Superior (Simulación) ---
H.btnRun = addButton(panelTop, [0.30 0.25 0.13 0.5], '▶ INICIAR', C.btn_run, C.text, @onRun);
H.btnStop = addButton(panelTop, [0.45 0.25 0.13 0.5], '■ DETENER', C.btn_stop, C.text, @onStop);
H.btnClr = addButton(panelTop, [0.60 0.25 0.13 0.5], '⟲ LIMPIAR', C.btn_util, C.text, @onClear);
% --- Componentes en Panel Izquierdo (Modo) ---
H.btnPID = uicontrol(panelLeftMode, 'Style', 'togglebutton', 'String', 'PID Clásico', 'FontSize', 11, 'Units', 'normalized', 'Position', [0.05 0.5 0.9 0.35], 'Callback', @(~,~)setMode(1));
H.btnFZ = uicontrol(panelLeftMode, 'Style', 'togglebutton', 'String', 'PID Difuso', 'FontSize', 11, 'Units', 'normalized', 'Position', [0.05 0.1 0.9 0.35], 'Callback', @(~,~)setMode(0));
% --- Componentes en Panel Izquierdo (Referencia - Compactado) ---
H.cbShape = uicontrol(panelLeftRef, 'Style', 'checkbox', 'Units', 'normalized', 'Position', [0.05 0.80 0.9 0.15], 'String', 'Habilitar Suavizado', 'Value', evalin('base', 'enable_shape'), 'BackgroundColor', C.panel, 'ForegroundColor', C.text, 'FontSize', 11, 'Callback', @pushBezierParams);
H.edCmd = addEdit(panelLeftRef, [0.05 0.55 0.4 0.18], 'Setpoint (w_cmd)', C, @pushBezierParams, num2str(evalin('base', 'w_cmd')));
H.edTd = addEdit(panelLeftRef, [0.55 0.55 0.4 0.18], 'Duración Td [s]', C, @pushBezierParams, num2str(evalin('base', 'Td')));
uicontrol(panelLeftRef,'Style','text','String','Ajuste Setpoint (Potenciómetro)','Units','normalized','Position',[0.05 0.35 0.9 0.1],'BackgroundColor',C.panel,'ForegroundColor',C.text,'HorizontalAlignment','left','FontSize',10);
H.sliCmd = uicontrol(panelLeftRef, 'Style', 'slider', ...
    'Min', S.slider.min, 'Max', S.slider.max, 'Value', evalin('base', 'w_cmd'), ...
    'Units', 'normalized', 'Position', [0.05 0.15 0.9 0.15], ...
    'Callback', @pushBezierParams);
    
% =======================================================================
% INICIO DE LA CORRECCIÓN (Layout del Panel TCP)
% =======================================================================
% --- Componentes en Panel TCP ---
% [x, y, w, h]
H.edIP = addEdit(panelTCP, [0.05 0.60 0.40 0.25], 'Dirección IP Servidor', C, [], '127.0.0.1');
H.edPort = addEdit(panelTCP, [0.55 0.60 0.40 0.25], 'Puerto', C, [], '13000');
H.btnConnect = addButton(panelTCP, [0.05 0.30 0.40 0.25], 'CONECTAR', C.btn_run, C.text, @onConnectTCP);
H.btnDisconnect = addButton(panelTCP, [0.55 0.30 0.40 0.25], 'DESCONECTAR', C.btn_stop, C.text, @onDisconnectTCP);
H.txtTCPStatus = uicontrol(panelTCP, 'Style', 'text', 'String', 'Estado: Desconectado', 'FontSize', 10, 'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.15], 'BackgroundColor', C.panel, 'ForegroundColor', C.text, 'HorizontalAlignment', 'center');
set(H.btnDisconnect, 'Enable', 'off');
% =======================================================================
% FIN DE LA CORRECCIÓN
% =======================================================================

% --- Gráfica y Estado ---
H.ax = axes('Parent', H.f, 'Position', [0.35 0.12 0.62 0.72], 'Color', C.edit_bg, 'XColor', C.text, 'YColor', C.text, 'GridColor', C.grid, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');
title(H.ax, 'Respuesta del Sistema', 'Color', C.text, 'FontSize', 14);
xlabel(H.ax, 'Tiempo (s)', 'Color', C.text); ylabel(H.ax, 'Velocidad', 'Color', C.text); hold(H.ax, 'on');
H.hRef = plot(H.ax, NaN, NaN, '--', 'Color', C.plot_ref, 'LineWidth', 2.0, 'DisplayName', 'Referencia ($\omega_{ref}$)');
H.hMeas = plot(H.ax, NaN, NaN, '-', 'Color', C.plot_meas, 'LineWidth', 2.5, 'DisplayName', 'Medida ($\omega_{meas}$)');
legend(H.ax, 'TextColor', C.text, 'Interpreter', 'latex', 'Location', 'southeast');
H.txtStatus = uicontrol(H.f, 'Style', 'text', 'String', 'Listo.', 'Position', [10 5 H.f.Position(3)-20 25], 'BackgroundColor', C.bg, 'ForegroundColor', C.text, 'FontSize', 11, 'HorizontalAlignment', 'center');
setMode(evalin('base', 'use_pid'));
set(H.f, 'SizeChangedFcn', @onResize);

% -------------------------------------------------------------------------
% 3. TEMPORIZADOR Y FUNCIONES DE CALLBACK
% -------------------------------------------------------------------------
% (El resto del código es idéntico al que proporcionaste, 
% ya que era correcto)
% ... (onRun, onStop, onClear, pushBezierParams, setMode) ...
% ... (onConnectTCP, onDisconnectTCP) ...
    
% Rutas a los bloques de Simulink
S.path.use_pid = 'General_2/use_pid';
S.path.w_cmd = 'General_2/w_cmd';
S.path.td = 'General_2/Td';
S.path.enable_shape = 'General_2/enable_shape';
H.tmr = timer('ExecutionMode', 'fixedRate', 'Period', 0.01, 'TimerFcn', @onTick);
    function onRun(~, ~)
        setStatus('Iniciando...', C.plot_ref);
        pushBezierParams(H.edCmd, []); 
        try
            set_param(S.mdl, 'SimulationCommand', 'start');
        catch ME
            errordlg(ME.message);
            setStatus('Error al iniciar.', C.btn_stop);
            return;
        end
        if isempty(S.t0), S.t0 = tic; end
        if ~strcmp(H.tmr.Running, 'on'), start(H.tmr); end
        setStatus('Simulación en curso...', C.btn_run);
    end
    function onStop(~, ~)
        if strcmp(get_param(S.mdl, 'SimulationStatus'), 'running')
            set_param(S.mdl, 'SimulationCommand', 'stop');
        end
        if strcmp(H.tmr.Running, 'on'), stop(H.tmr); end
        setStatus('Simulación detenida.', C.text);
    end
    function onClear(~, ~)
        onStop();
        S.t0=[]; S.t=[]; S.y=[]; S.r=[];
        set(H.hMeas,'XData',NaN,'YData',NaN);
        set(H.hRef,'XData',NaN,'YData',NaN);
        xlim(H.ax,'auto'); ylim(H.ax,'auto');
        title(H.ax,'Respuesta del Sistema');
        setStatus('Gráfica y datos limpiados.',C.text);
    end
    function pushBezierParams(src, ~)
        % --- Sincronizar Slider y Edit Box ---
        if src == H.sliCmd % Si el usuario movió el slider
            val = get(H.sliCmd, 'Value');
            set(H.edCmd, 'String', num2str(val, '%.2f')); % Actualiza el texto
        elseif src == H.edCmd % Si el usuario escribió en el texto
            val = str2double(get(H.edCmd, 'String'));
            if isnan(val), val = H.sliCmd.Value;
            elseif val < S.slider.min, val = S.slider.min;
            elseif val > S.slider.max, val = S.slider.max;
            end
            set(H.edCmd, 'String', num2str(val, '%.2f')); 
            set(H.sliCmd, 'Value', val);
        end
        
        drawnow; % Forzar actualización visual
        
        % --- Enviar TODOS los parámetros de referencia a Simulink ---
        new_w_cmd = str2double(H.edCmd.String);
        new_Td = str2double(H.edTd.String);
        new_enable_shape = double(H.cbShape.Value);
        
        assignin('base','w_cmd', new_w_cmd);
        assignin('base','Td', new_Td);
        assignin('base','enable_shape', new_enable_shape);
        
        try
            if strcmp(get_param(S.mdl,'SimulationStatus'),'running')
                set_param(S.path.w_cmd,'Value',num2str(new_w_cmd));
                set_param(S.path.td,'Value',num2str(new_Td));
                set_param(S.path.enable_shape,'Value',num2str(new_enable_shape));
                setStatus('Parámetros de referencia actualizados en tiempo real.',C.plot_ref);
            else
                setStatus('Parámetros de referencia actualizados.',C.text);
            end
        catch ME
            warning('Error al actualizar parámetros de referencia: %s', ME.message);
            setStatus('Error actualizando parámetros de referencia.',C.btn_stop);
        end
    end
    function setMode(isPID)
        assignin('base','use_pid',double(isPID));
        H.btnPID.Value=isPID;
        H.btnFZ.Value=~isPID;
        if isPID
            H.btnPID.BackgroundColor=C.btn_run;
            H.btnFZ.BackgroundColor=C.btn_util;
            new_status='Modo: PID Clásico.';
        else
            H.btnPID.BackgroundColor=C.btn_util;
            H.btnFZ.BackgroundColor=C.btn_run;
            new_status='Modo: PID Difuso.';
        end
        try
            if strcmp(get_param(S.mdl,'SimulationStatus'),'running')
                set_param(S.path.use_pid,'Value',num2str(isPID));
                setStatus([new_status ' (Actualizado en tiempo real)'],C.plot_ref);
            else
                setStatus(new_status, C.text);
            end
        catch ME
            warning('Error al cambiar modo de control: %s', ME.message);
            setStatus('Error cambiando modo.',C.btn_stop);
        end
    end
    % --- FUNCIONES TCP ---
    function onConnectTCP(~, ~)
        if ~isempty(S.tcp.client), return; end
        ip = H.edIP.String; port = str2double(H.edPort.String);
        set(H.txtTCPStatus, 'String', sprintf('Conectando a %s:%d...', ip, port), 'ForegroundColor', C.text); drawnow;
        try
            S.tcp.client = tcpclient(ip, port, 'Timeout', 5);
            set(H.txtTCPStatus, 'String', '¡Conectado!', 'ForegroundColor', C.btn_run);
            % Envío de datos cada 1.0 segundo (como solicitaste)
            S.tcp.senderTimer = timer('ExecutionMode', 'fixedRate', 'Period', 1.0, 'TimerFcn', @sendTCPData);
            start(S.tcp.senderTimer);
            set(H.btnConnect, 'Enable', 'off'); set(H.btnDisconnect, 'Enable', 'on');
        catch ME
            set(H.txtTCPStatus, 'String', 'Error de conexión.', 'ForegroundColor', C.btn_stop);
            errordlg(sprintf('No se pudo conectar al servidor TCP: %s', ME.message), 'Error TCP');
            clear S.tcp.client; S.tcp.client = [];
        end
    end
    function onDisconnectTCP(~, ~)
        if isempty(S.tcp.client), return; end
        if ~isempty(S.tcp.senderTimer) && isvalid(S.tcp.senderTimer), stop(S.tcp.senderTimer); delete(S.tcp.senderTimer); S.tcp.senderTimer = []; end
        clear S.tcp.client; S.tcp.client = [];
        set(H.txtTCPStatus, 'String', 'Estado: Desconectado', 'ForegroundColor', C.text);
        set(H.btnConnect, 'Enable', 'on'); set(H.btnDisconnect, 'Enable', 'off');
    end

    function sendTCPData(~, ~)
        if isempty(S.tcp.client) || ~isvalid(S.tcp.client), onDisconnectTCP(); return; end
        
        % --- ESTA ES LA LÓGICA CORRECTA (v2.6) ---
        
        % Intentar leer las variables. Si fallan, usar 0.
        % La nueva tryEval() aceptará 'fi' para voltaje_live.
        [ok_ref, w_ref] = tryEval('w_ref_live');
        if ~ok_ref, w_ref = 0; end
        
        [ok_meas, w_meas] = tryEval('w_meas_live');
        if ~ok_meas, w_meas = 0; end
        [ok_volt, v_volt] = tryEval('voltaje_live'); 
        if ~ok_volt, v_volt = 0; end
    
        try
            % Convertir a double (sin redondear)
            % double() convierte 'fi' a 'double' sin problema
            ref_val = double(w_ref); 
            meas_val = double(w_meas);
            volt_val = double(v_volt);
            
            % Formato: "Buscada,Real,Voltaje\n" con 2 decimales
            msg = sprintf('%.2f,%.2f,%.2f\n', ref_val, meas_val, volt_val);
            write(S.tcp.client, uint8(msg));
            set(H.txtTCPStatus, 'String', 'Enviando datos...', 'ForegroundColor', C.btn_run);
        catch ME
            set(H.txtTCPStatus, 'String', 'Error de envío.', 'ForegroundColor', C.btn_stop);
            warning('Error al enviar datos por TCP: %s', ME.message); 
            onDisconnectTCP();
        end
        % --- FIN DE LA LÓGICA ---
    end
    % --- FIN FUNCIONES TCP ---
    function onTick(~, ~)
        if ~strcmp(get_param(S.mdl,'SimulationStatus'),'running'), onStop(); return; end
        [ok_m,w_m]=tryEval('w_meas_live'); [ok_r,w_r]=tryEval('w_ref_live');
        if ~(ok_m && ok_r), return; end
        t=toc(S.t0); S.t(end+1)=t; S.y(end+1)=double(w_m); S.r(end+1)=double(w_r);
        set(H.hMeas,'XData',S.t,'YData',S.y); set(H.hRef,'XData',S.t,'YData',S.r);
        updateAxes(t);
        title(H.ax,sprintf('Respuesta | t: %.2fs | Error: %.3f',t,w_r-w_m),'Color',C.text);
    end
    function updateAxes(t)
        if numel(S.t) < 2, return; end
        miny = min([S.y, S.r]); maxy = max([S.y, S.r]);
        pad = max(0.1, 0.1 * (maxy - miny));
        if isinf(pad) || isnan(pad) || pad == 0, pad = 1; end
        ylim(H.ax, [miny - pad, maxy + pad]);
        w = 20; if t > w, xlim(H.ax, [t - w, t]); else, xlim(H.ax, [0, w]); end
    end
    function onResize(~, ~)
        fig_pos = get(H.f, 'Position');
        set(H.txtStatus, 'Position', [10 5 fig_pos(3)-20 25]);
        drawnow;
    end
    function onClose(~, ~)
        onStop();
        onDisconnectTCP(); % Asegurarse de cerrar la conexión
        if isfield(H,'tmr') && isvalid(H.tmr'), delete(H.tmr); end
        delete(H.f);
    end
    function setStatus(msg, color), set(H.txtStatus,'String',msg,'ForegroundColor',color); end
end
% --- FUNCIONES AUXILIARES EXTERNAS ---
function ensure(varName, defaultVal)
    if ~evalin('base',sprintf('exist(''%s'',''var'');',varName))
        assignin('base',varName,defaultVal);
    end
end
% --- REEMPLAZA TU FUNCIÓN tryEval CON ESTA ---
function [ok, val] = tryEval(varName)
% Esta versión de tryEval acepta tipos 'double' y 'fi' (fixed-point).
    try
        val = evalin('base', varName);
        
        % Comprobación de tipo de dato:
        % Acepta si es numérico O si es un objeto 'fi'
        is_valid_type = isnumeric(val) || isa(val, 'embedded.fi');
        
        % Comprobación de tamaño y validez
        ok = isscalar(val) && is_valid_type && isfinite(val);
        
    catch
        val = NaN;
        ok = false;
    end
end
% --- FIN DE LA FUNCIÓN REEMPLAZADA ---
function H_btn = addButton(parent, pos, label, bgColor, fgColor, callback)
    H_btn = uicontrol(parent,'Style','pushbutton','String',label,'Units','normalized','Position',pos,'FontSize',12,'FontWeight','bold','BackgroundColor',bgColor,'ForegroundColor',fgColor,'Callback',callback);
end
% --- Función auxiliar para crear un Edit Box con su etiqueta ---
% =======================================================================
% INICIO DE LA CORRECCIÓN (Altura de la etiqueta)
% =======================================================================
function H_edit = addEdit(parent, pos, label, colors, callback, val)
    % Posición de la etiqueta (arriba del campo de texto)
    l_pos = [pos(1), pos(2) + pos(4) - 0.01, pos(3), 0.08]; % <-- Altura corregida (era 0.3)
    uicontrol(parent,'Style','text','String',label,'Units','normalized','Position',l_pos,'BackgroundColor',colors.panel,'ForegroundColor',colors.text,'HorizontalAlignment','left','FontSize',10);
    % Posición del campo de texto (la 'pos' original)
    H_edit = uicontrol(parent,'Style','edit','String',val,'FontSize',11,'Units','normalized','Position',pos,'BackgroundColor',colors.edit_bg,'ForegroundColor',colors.text,'Callback',callback);
end
% =======================================================================
% FIN DE LA CORRECCIÓN
% =======================================================================