function tcp_sender_three(ip, port)
% Envía "rpm_actual,rpm_deseado,voltage\n" en ASCII a ~10 Hz
% Sin caerse si faltan variables o hay errores en el workspace.

    %--- Conexión ---
    fprintf('Conectando a %s:%d...\n', ip, port);
    c = tcpclient(ip, port, 'Timeout', 5);
    fprintf('Conectado.\n');

    % Cierre limpio al salir (Ctrl+C o error no capturado)
    cleaner = onCleanup(@() closeClient());

    fprintf('Enviando. Ctrl+C para detener.\n');
    while true
        %--- Intentar leer variables del base workspace ---
        haveVars = true;
        try
            ra = evalin('base','rpm_actual');   % actual
            rd = evalin('base','rpm_deseado');  % deseado
            vo = evalin('base','voltage');      % voltage
        catch meGet
            haveVars = false;
            fprintf('Esperando rpm_actual/rpm_deseado/voltage... (%s)\n', meGet.message);
        end

        if haveVars
            if isnumeric(ra)&&isscalar(ra) && isnumeric(rd)&&isscalar(rd) && isnumeric(vo)&&isscalar(vo)
                msg = sprintf('%d,%d,%d\n', round(ra), round(rd), round(vo));
                try
                    write(c, uint8(msg));
                    fprintf('TX: %s', msg);
                catch meWrite
                    % Mantener vivo: no cortar el bucle; intentar reconectar
                    fprintf('Fallo al enviar: %s. Intentando reconectar...\n', meWrite.message);
                    try, clear c; pause(0.25); end
                    try
                        c = tcpclient(ip, port, 'Timeout', 5);
                        fprintf('Reconectado.\n');
                    catch meRe
                        fprintf('Reconexión fallida: %s\n', meRe.message);
                    end
                end
            else
                fprintf('Variables no escalares/numéricas. Esperando...\n');
            end
        end

        pause(0.1);           % ~10 Hz
        drawnow limitrate;    % opcional para GUIs
    end

    function closeClient()
        try, clear c; catch, end
        disp('Cliente cerrado.');
    end
end
