classdef MembershipFunctions < matlab.System
    properties (Nontunable)
        N = 5;
        Range = [-15, 15];   % EN GRADOS
        InputIsRadians = true;
    end
    methods (Access = protected)
        function mu = stepImpl(obj, valor)
            if obj.InputIsRadians
                valor = valor * 180/pi;   % <-- conversión rad -> deg
            end
            mu = zeros(1,obj.N);
            rmin = obj.Range(1); rmax = obj.Range(2);
            step = (rmax - rmin) / (obj.N - 1);
            centers = rmin:step:rmax;
            for i = 1:obj.N
                if i == 1
                    if valor <= centers(1)
                        mu(i)=1;
                    elseif valor >= centers(2)
                        mu(i)=0;
                    else
                        mu(i)=(centers(2)-valor)/(centers(2)-centers(1));
                    end
                elseif i == obj.N
                    if valor >= centers(end)
                        mu(i)=1;
                    elseif valor <= centers(end-1)
                        mu(i)=0;
                    else
                        mu(i)=(valor-centers(end-1))/(centers(end)-centers(end-1));
                    end
                else
                    left=centers(i-1); mid=centers(i); right=centers(i+1);
                    if valor==mid
                        mu(i)=1;
                    elseif valor>left && valor<mid
                        mu(i)=(valor-left)/(mid-left);
                    elseif valor>mid && valor<right
                        mu(i)=(right-valor)/(right-mid);
                    else
                        mu(i)=0;
                    end
                end
            end
        end
        function outSize = getOutputSizeImpl(obj), outSize=[1 obj.N]; end
        function outType = getOutputDataTypeImpl(~), outType='double'; end
        function cflag   = isOutputComplexImpl(~),   cflag=false; end
    end
end
