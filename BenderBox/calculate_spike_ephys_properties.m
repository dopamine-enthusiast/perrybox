function [name sweep num_spikes AP_max AP_amplitude AP_width] = calculate_spike_ephys_properties(Cell)



%Find the number of spikes per sweeps for spikes generated by current injection in the first 3 minutes
for i=1:length(Cell.commands(1,:))
    if max(Cell.commands(:,i)) > 0 &&...
            Cell.sweep_time(i) < 180 &&...
            mean(Cell.data(1:50,i)) < -65 &&...
            Cell.kHz(i) == 50
        idx = find(Cell.commands(:,i));
        idx = idx(100:end);
        Vm = Cell.data(idx,i)-12;
        time = Cell.time(idx,i);
        dVdt = gradient(Vm)./gradient(time)./1000;
        
   
        if max(dVdt) > 15 
            AP_start_idx = find(dVdt > 15,1);%the start
            
            
            if max(Vm(AP_start_idx:AP_start_idx+500)) >-15
                num_spikes_per_sweep(i) = sum(diff(find(dVdt > 15)) > 1) + 1;
            else
                num_spikes_per_sweep(i) = 0;
            end
            
        else
            num_spikes_per_sweep(i) = 0;
        end
    else
        num_spikes_per_sweep(i) = 0;
    end
end

num_spikes = min(num_spikes_per_sweep(num_spikes_per_sweep>0));


if num_spikes
    try
        sweep = find(num_spikes_per_sweep == num_spikes,1);
        idx = find(Cell.commands(:,sweep));
        idx = idx(100:end);
        Vm = Cell.data(idx,sweep)-12;
        time = Cell.time(idx,sweep);
        dVdt = gradient(Vm)./gradient(time)./1000;
        
        AP_start_idx = find(dVdt > 15,1);%the start
        temp = find(dVdt(AP_start_idx:end) < 0,1)+AP_start_idx; %The peak
        AP_end_idx = find(dVdt(temp:end) > 0,1)+temp;

        AP_threshold = Vm(AP_start_idx);        
        
        AP_Vm = Vm(AP_start_idx:AP_end_idx);
        AP_Time = time(AP_start_idx:AP_end_idx);
        [AP_max] = max(AP_Vm);
        AP_amplitude = max(AP_Vm)-AP_threshold;
        
        AP_top50_idx = find(AP_Vm > AP_threshold + (AP_amplitude*.5));
        AP_width = AP_Time(AP_top50_idx(end))-AP_Time(AP_top50_idx(1));
        
        name = Cell.name;
        figure;
        hold on;
        plot(AP_Time,AP_Vm);
        plot([AP_Time(AP_top50_idx(1)) AP_Time(AP_top50_idx(end))], [AP_Vm(AP_top50_idx(1)) AP_Vm(AP_top50_idx(end))],'r')
        title(Cell.name);
    catch
    end
    
else
    name =Cell.name;
    sweep =NaN;
    num_spikes =NaN;
    AP_max =NaN;
    AP_amplitude =NaN;
    AP_width=NaN;
end

