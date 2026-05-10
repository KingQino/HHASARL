function [ruta,rutaC]=AddStation(ruta,model)
EvalCounter('add_partial', 1);
estaciones=check_station(ruta,model);
rutaC=ruta;
cont=1;
for j=1:length(estaciones)
    n=estaciones(j)+cont-1;
    if n < 1 || n >= length(ruta) || n >= length(rutaC)
        continue;
    end
    if ruta(n)==-1 || ruta(n+1)==-1
        continue;
    end

    EvalCounter('add_partial', 1);
    station=nearstation(zeros(model.STATIONS,1),rutaC(n)+1,rutaC(n+1)+1,model);
    ruta=[ruta(1:n) -1 ruta(n+1:end)];
    rutaC=[rutaC(1:n) station+model.SIZE-1 rutaC(n+1:end)];
    cont=cont+1;
end
end
