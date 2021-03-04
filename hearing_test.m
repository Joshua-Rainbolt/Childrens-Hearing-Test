
function hearing_test()
user_input=0;
current_sound=0;
noise_rms=0.035;
num_row=0;
SNR = 0;
fs = 44100;
duration = 0.3;
x=0;
vec_val=zeros(0,x);

Test = figure('Name', 'Hearing Test',...
    'Color', 'c',...
    'Units', 'inches',...
    'windowstate', 'fullscreen');

sound_button = uicontrol('Style','pushbutton',...
    'Units','pixels',...
    'Position',[600 400 300 200],...
    'String','Push For Sound',...
    'Callback',@test,...
    'BackgroundColor','w',...
    'ForegroundColor','blue',...
    'FontSize',14,...
    'FontName','Calibri',...
    'FontWeight','bold');

button_1 = uicontrol('Style','pushbutton',...
    'Units','pixels',...
    'Position',[400 100 300 200],...
    'String','Tone',...
    'BackgroundColor','Green',...
    'Callback',@btn_1,...
    'ForegroundColor','w',...
    'FontSize',14,...
    'FontName','Calibri',...
    'FontWeight','bold');
    
button_2 = uicontrol('Style','pushbutton',...
    'Units','pixels',...
    'Position',[800 100 300 200],...
    'String','No Tone',...
    'BackgroundColor','red',...
    'Callback',@btn_2,...
    'ForegroundColor','w',...
    'FontSize',14,...
    'FontName','Calibri',...
    'FontWeight','bold');

instructions = uicontrol('Style', 'text',...
    'Position', [525 700 450 45],...
    'String', 'Push the "Push for Sound" button to play the sound, then choose if you hear a tone or just noise.',...
    'FontSize',14,...
    'FontName','Calibri',...
    'FontWeight','bold');


button_1.Visible = 'off';
button_2.Visible = 'off';
instructions.Visible = 'on';
sound_button.Visible = 'on';


%Plays a tone and white noise.
    function test_stimulus = gen_test_stimulus(~)

        
        N = fs*duration; % number of samples
        t = (0:N-1).'/fs; % time vector, transposed to make it a column
        f = 500; % tone frequency, Hz
        sine_wave = sin(2*pi*f*t);
        
        % Apply ramp to first and last 25 ms.
        ramp = tukeywin(N,2*0.025/duration);
        ramped_sine_wave = ramp.*sine_wave;
        
        % Scale the tone to the desired RMS level.
        desired_tone_rms = noise_rms*10.^(SNR/20);
        sine_wave_scaled = ramped_sine_wave * desired_tone_rms / ...
            rms(ramped_sine_wave);
        
        % Generate an instance of noise.
        noise = gen_noise_stimulus();
        
        % Add the noise and the tone.
        test_stimulus = noise + sine_wave_scaled;
        sound(test_stimulus, fs);
    end

%Plays white noise
    function noise_stimulus = gen_noise_stimulus(~)
        
        fn = fs/2; % Nyquist frequency = half the sample rate
        N = fs*duration; % number of samples
        white_noise = randn(N,1); 
        
        % column vector of noise samples.
        % Build an FIR filter and transpose the coefficients to make a
        % column vector, FIR means finite impulse response filter
        freq_range = [100 3000]; % Hz
        b = fir1(5000,freq_range/fn).';
        
        % Generate the ramp for first and last 25 ms.
        ramp = tukeywin(N,2*0.025/duration);
        % Apply the filter and ramp to the white noise.
        noise = ramp.*conv(white_noise,b,'same');
        % Scale the noise to the desired RMS level.
        
        noise_stimulus = noise*noise_rms/rms(noise);
        sound (noise_stimulus, fs);
    end


    function btn_1_value = btn_1(~,~)
        button_1.Visible = 'off';
        button_2.Visible = 'off';
        user_input=1;
        ws= which_sound;
        chng_db(ws)             
        
        sound_button.Visible = 'on';
    end

    function btn_2_value =btn_2(~,~)
        button_1.Visible = 'off';
        button_2.Visible = 'off';
        user_input=2;
        ws= which_sound;
        chng_db(ws)
        
        sound_button.Visible = 'on';
        
    end

%Identifies if the user got the answer right and sets this to a variable.
    function corr_ident = which_sound(~,~)
        if user_input==current_sound          
            corr_ident=1;
            num_row=num_row+1;
            good = imshow('great_job.png');
            pause(2);
            good.Visible = 'off';
            
        else
            corr_ident=0;           
            num_row=0;
            bad = imshow('thumbs_down.png');
            pause(2);
            bad.Visible = 'off';
            
        end
        return
        
    end

%Checks if the user got the answer right. If they did, and they also got
%the last answer right, it decreases SNR. If they got it incorrect, it
%decreases SNR.
    function chng_db(corr_ident)
        if corr_ident==1
            if num_row==2
                SNR=SNR-1;
                num_row=0;
            elseif num_row == 0
                
            end
            
        else
            SNR=SNR+1;
            if num_row > 0
                
                num_row = 0;
            end
        end
        vec_val(x)=SNR;
    end

%chooses randomly to play a tone or white noise
    function hear_trial(~,~)      
        sounds=[1,2];
        pos =randi(2);
        sound_now =sounds(pos);
        if sound_now==1
            current_sound=1;
            gen_test_stimulus();
            button_1.Visible = 'on';
            button_2.Visible = 'on';
        else
            current_sound=2;
            gen_noise_stimulus();
             button_1.Visible = 'on';
             button_2.Visible = 'on';
        end
        
    end

%Controls how long the test is run for by tracking how many peaks
    function test(~,~)       
        x=x+1;
        game = ((sum(islocalmax(vec_val))+(sum(islocalmin(vec_val)))));
        if game < 8
            sound_button.Visible = 'off';           
            hear_trial();
        else
            open_graph();
        end
    end

%Opens the graph of the test results
     function open_graph()
        Test.Visible = 'off';
        graph = figure;
        graph.Visible = 'on';
        trial_nums = 0:x-2;
        max=islocalmax(vec_val);
        min=islocalmin(vec_val);
        plot(trial_nums,vec_val,trial_nums(max),vec_val(max),'r*',...
            trial_nums(min),vec_val(min),'r*')
        xlabel('trial number')
        ylabel('SNR')
        title('Hearing Test Results')
        set(gca, 'XTick', 0:x,...
            'YTick', vec_val)
    end


end


