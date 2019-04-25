function plotSensorResponse(dt)
    t = dt(:,1);
    
    figure;
    hold on;
    grid on;
    
    plot(t, dt(:,2));
    plot(t, dt(:,3));
    plot(t, dt(:,4));
    plot(t, dt(:,5));
    plot(t, dt(:,6));
    plot(t, dt(:,7));
    plot(t, dt(:,8));
    plot(t, dt(:,9));
end