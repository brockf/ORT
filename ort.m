function [] = ort ()
    %% LOAD CONFIGURATION %%
    
    % get experiment directory
    base_dir = [ uigetdir([], 'Select experiment directory') '/' ];
    
    % load the tab-delimited configuration file
    config = ReadStructsFromText([base_dir 'config.txt']);
    
    disp(sprintf('You are running %s\n\n',get_config('StudyName')));

    %% SETUP EXPERIMENT AND SET SESSION VARIABLES %%
    
    % tell matlab to shut up, and seed it's random numbers
    warning('off','all');
    random_seed = sum(clock);
    rand('twister',random_seed);

    [ year, month, day, hour, minute, sec ] = datevec(now);
    start_time = [num2str(year) '-' num2str(month) '-' num2str(day) ' ' num2str(hour) ':' num2str(minute) ':' num2str(sec) ];
    
    % get subject code
    experimenter = input('Enter your (experimenter) name: ','s');
    subject_code = input('Enter subject code: ', 's');
    subject_sex = input('Enter subject sex (M/F):  ', 's');
    subject_age = input('Enter subject age (in months; e.g., X.XX): ', 's');
    order_number = input(sprintf('Which order would you like to run the baby in? (1-%s): ',num2str(get_config('Orders'))), 's');
    
    % begin logging now, because we have the subject_code
    create_log_file();
    log_msg(sprintf('Set base dir: %s',base_dir));
    log_msg('Loaded config file');
    log_msg(sprintf('Study name: %s',get_config('StudyName')));
    log_msg(sprintf('Random seed set as %s via "twister"',num2str(random_seed)));
    log_msg(sprintf('Start time: %s',start_time));
    log_msg(sprintf('Experimenter: %s',experimenter));
    log_msg(sprintf('Subject Code: %s',subject_code));
    log_msg(sprintf('Subject Sex: %s',subject_sex));
    log_msg(sprintf('Subject Age: %s',subject_age));
    log_msg(sprintf('Order Number: %s',order_number));
    
    % initiate data structure for session file
    data = struct('key',{},'value',{});

    %% GET ORDER BY ENTERED NUMBER %%
    order_code = get_config(sprintf('Order%s',order_number));
    
    % replace quotation marks in order_code string (Excel saves with these,
    % sometimes)
    order_code = regexprep(order_code,'["'']','');
    
    log_msg(sprintf('Order code: %s',order_code));
    disp(sprintf('\n\nFinal Order Code: %s', order_code));
    
    [test_trials,num_test_trials] = explode(order_code,',');
    
    %% LOAD STIMULI %%

    % load in familiarization stimuli
    cd(base_dir);

    % gather images
    stimuli = dir(['./' get_config('StimuliFolder')]);
    
    % wait for experimenter to press Enter to begin
    disp(upper(sprintf('\n\nPress any key to launch the experiment window\n\n')));
    KbWait([], 2);
    
    log_msg('Experimenter has launched the experiment window');

    %% SETUP SCREEN %%

    if (get_config('DebugMode') == 1)
        % skip sync tests for faster load
        Screen('Preference','SkipSyncTests', 1);
        log_msg('Running in DebugMode');
    else
        % shut up
        Screen('Preference', 'SuppressAllWarnings', 1);
        log_msg('Not running in DebugMode');
    end

    % disable the keyboard
    ListenChar(2);

    % create window
    screen_number = max(Screen('Screens'));
    wind = Screen('OpenWindow',screen_number);
    
    log_msg(sprintf('Using screen #%s',num2str(screen_number)));
    
    % initialize sound driver
    log_msg('Initializing sound driver...');
    InitializePsychSound;
    log_msg('Sound driver initialized.');
    
    % we may want PNG images
    Screen('BlendFunction', wind, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    % grab height and width of screen
    res = Screen('Resolution',screen_number);
    sheight = res.height;
    swidth = res.width;
    winRect = Screen('Rect', wind);
    
    log_msg(sprintf('Screen resolution is %s by %s',num2str(swidth),num2str(sheight)));

    % wait to begin experiment
    Screen('TextFont', wind, 'Helvetica');
    Screen('TextSize', wind, 25);
    DrawFormattedText(wind, 'Press any key to begin!', 'center', 'center');
    Screen('Flip', wind);

    KbWait([], 2);
    
    log_msg('Experimenter has begun experiment.');

    %% RUN EXPERIMENT TRIALS %%
    
    % attract initial attention
    attention_getter();
    
    % SET POSITIONS OF OBJECTS ON STAGE FOR DURATION OF EXPERIMENT
    if (randi(2) == 1)
        pos_left = 'Object1';
        pos_right = 'Object2';
    else
        pos_left = 'Object2';
        pos_right = 'Object1';
    end
    
    % FAMILIARIZATION
    
    for i = 1:5
        % start the fam trial
        [looking_time_left looking_time_right] = fam_trial();
        
        % record data from fam trial to data and log
        add_data(sprintf('FamTrial%sLT_Left',num2str(i)),num2str(looking_time_left));
        add_data(sprintf('FamTrial%sLT_Right',num2str(i)),num2str(looking_time_right));
        add_data(sprintf('FamTrial%sLT_Total',num2str(i)),num2str(looking_time_left + looking_time_right));
        log_msg(sprintf('FamTrial%sLT_Left: %s',num2str(i),num2str(looking_time_left)));
        log_msg(sprintf('FamTrial%sLT_Right: %s',num2str(i),num2str(looking_time_right)));
        log_msg(sprintf('FamTrial%sLT_Total: %s',num2str(i),num2str(looking_time_left + looking_time_right)));
    end
    
    % TEST TRIALS
    for i = 1:length(test_trials)
        % what type of test trial is this?
        test_condition = test_trials{i};
        
        add_data(sprintf('TestTrial%sCondition',num2str(i)),test_condition);
        log_msg(sprintf('TestTrial%sCondition: %s',num2str(i),test_condition));
        
        % get their attention
        test_attention_getter();
        
        % each test trial begins with one fam trial
        [looking_time_left looking_time_right first_moved_object] = fam_trial();
        
        add_data(sprintf('TestTrial%sFamLT_Left',num2str(i)),num2str(looking_time_left));
        add_data(sprintf('TestTrial%sFamLT_Right',num2str(i)),num2str(looking_time_right));
        add_data(sprintf('TestTrial%sFamLT_Total',num2str(i)),num2str(looking_time_left + looking_time_right));
        log_msg(sprintf('TestTrial%sFamLT_Left: %s',num2str(i),num2str(looking_time_left)));
        log_msg(sprintf('TestTrial%sFamLT_Right: %s',num2str(i),num2str(looking_time_right)));
        log_msg(sprintf('TestTrial%sFamLT_Total: %s',num2str(i),num2str(looking_time_left + looking_time_right)));
        
        % occluders are always the same graphs
        left_occluder_name = get_config('OccluderL');
        right_occluder_name = get_config('OccluderR');
        
        % set the object images and positions
        % we change these depending on condition (except baseline)
        if (strcmp(pos_left,'Object1') == true)
            left_object_name = get_config('Object1');
            right_object_name = get_config('Object2');
        else
            left_object_name = get_config('Object2');
            right_object_name = get_config('Object1');
        end
        
        left_object_displaced = 0;
        right_object_displaced = 0;
        left_occluder_displaced = 0;
        right_occluder_displaced = 0;
        
        % following Kibbe & Leslie (2011), we may see differences between
        % when we change the first or last hidden object, so we will record
        % this data for the sake of the SF trials (where only one object
        % changes)
        add_data(sprintf('TestTrial%sFirstHiddenObject',num2str(i)),first_moved_object);
        log_msg(sprintf('TestTrial%sFirstHiddenObject: %s',num2str(i),first_moved_object));
        
        % depending on the test trial type, we are going to either move our
        % objects (displace) or replace one of our objects
        if (strcmp(test_condition,'BL'))
            % baseline - no changes!
        elseif (strcmp(test_condition,'SF'))
            % replace one of the objects with a novel object
            % randomize which object is replaced
            if (randi(2) == 2)
                left_object_name = get_config('Object3');
                novel_object_side = 'left';
            else
                right_object_name = get_config('Object3');
                novel_object_side = 'right';
            end
            
            % see note about Kibbe & Leslie (2011) above...
            add_data(sprintf('TestTrial%sNovelObject',num2str(i)),novel_object_side);
            log_msg(sprintf('TestTrial%sNovelObject: %s',num2str(i),novel_object_side));
        elseif (strcmp(test_condition,'ST'))
            % move the objects beside each other under
            % a random occluder
            if (randi(2) == 2)
                left_object_displaced = -(swidth/13);
                right_object_displaced = -(swidth/2.5);
            else
                left_object_displaced = -(swidth/2.5);
                right_object_displaced = -(swidth/13);
            end
        elseif (strcmp(test_condition,'FB'))
            % swap object positions with each other
            left_object_displaced = -(swidth/3);
            right_object_displaced = -(swidth/3);
        end 
        
        % pull up occluders
        movement_start_time = GetSecs;
        time_to_move = 1;
        distance = sheight / 3;
        while ((GetSecs - movement_start_time) <= time_to_move)
            % calculate how far it should be moved by the proportion of
            % the the total move time (1s) and the total distance to be
            % moved (20% of the screen)
            displacement = ((GetSecs - movement_start_time) / time_to_move) * distance;

            draw_stage(left_object_name,...
                       right_object_name,...
                       left_occluder_name,...
                       right_occluder_name,...
                       left_object_displaced,...
                       right_object_displaced,...
                       displacement,...
                       displacement);
        end
        
        % calculate looking time
        [looking_time] = freeze_frame(get_config('MaxTestDuration'), get_config('MaxLookaway'), 0);
        
        % pull down occluders
        movement_start_time = GetSecs;
        time_to_move = 1;
        distance = sheight / 3;
        while ((GetSecs - movement_start_time) <= time_to_move)
            % calculate how far it should be moved by the proportion of
            % the the total move time (1s) and the total distance to be
            % moved (20% of the screen)
            displacement = (1 - ((GetSecs - movement_start_time) / time_to_move)) * distance;

            draw_stage(left_object_name,...
                       right_object_name,...
                       left_occluder_name,...
                       right_occluder_name,...
                       left_object_displaced,...
                       right_object_displaced,...
                       displacement,...
                       displacement);
        end
        
        % record data
        add_data(sprintf('TestTrial%s_LT',num2str(i)),num2str(looking_time));
        log_msg(sprintf('TestTrial%s_LT: %s',num2str(i),num2str(looking_time)));
    end
    

    %% POST-EXPERIMENT CLEANUP %%

    post_experiment(false);

    %% HELPER FUNCTIONS %%
    function [value] = get_config (name)
        matching_param = find(cellfun(@(x) strcmpi(x, name), {config.Parameter}));
        value = [config(matching_param).Setting];
    end

    function [key_pressed] = key_pressed ()
        [~,~,keyCode] = KbCheck;
        
        if sum(keyCode) > 0
            key_pressed = true;
        else
            key_pressed = false;
        end
        
        % should we abort
        if strcmpi(KbName(keyCode),'ESCAPE')
            log_msg('Aborting experiment due to ESCAPE key press.');
            post_experiment(true);
        end
    end

    function [time_accumulated] = freeze_frame (max_ms, max_lookaway_ms, sound_file)
        keypress_start = 0;
        time_accumulated = 0;
        movement_start_time = GetSecs;
        last_look_end = 0;
        
        % do we have a sound file to play?
        if (sound_file ~= 0)
            sound_file = [base_dir get_config('StimuliFolder') '/' sound_file];
            log_msg(sprintf('Loading sound from: %s',sound_file));
        else
            sound_file = false;
        end
        
        if (sound_file ~= false)
            [wav, freq] = wavread(sound_file);
            wav_data = wav';
            num_channels = size(wav_data,1);
            
            try
                % Try with the 'freq'uency we wanted:
                pahandle = PsychPortAudio('Open', [], [], 0, freq, num_channels);
            catch
                % Failed. Retry with default frequency as suggested by device:
                psychlasterror('reset');
                pahandle = PsychPortAudio('Open', [], [], 0, [], num_channels);
            end
            
            % Fill the audio playback buffer with the audio data 'wavedata':
            PsychPortAudio('FillBuffer', pahandle, wav_data);

            % Start audio playback for 'repetitions' repetitions of the sound data,
            % start it immediately (0) and wait for the playback to start, return onset
            % timestamp.
            PsychPortAudio('Start', pahandle, 1, 0, 1);
        end
        
        % loop indefinitely
        while (1 ~= 2)
            % look for a keypress
            if key_pressed()
                if (keypress_start == 0)
                    % start a keypress
                    keypress_start = GetSecs();
                end
            else
                if (keypress_start > 0)
                    % add to accumulated time
                    time_accumulated = time_accumulated + (GetSecs - keypress_start);
                    last_look_end = GetSecs;
                end
                
                % reset keypress
                keypress_start = 0;
                
                % have we looked away for than the maximum lookaway?
                if (max_lookaway_ms > 0 && last_look_end > 0 && ((GetSecs - last_look_end) > (max_lookaway_ms / 1000)))
                    break
                end
            end
            
            % have we reached the maximium looking?
            if (GetSecs - movement_start_time >= (max_ms/1000))
                if (keypress_start > 0)
                    time_accumulated = time_accumulated + (GetSecs - keypress_start);
                end
                
                % end!
                break
            end
        end
        
        if (sound_file ~= false)
            % Stop sound
            PsychPortAudio('Stop', pahandle);

            % Close the audio device:
            PsychPortAudio('Close', pahandle);
        end
    end

    function [looking_time_left looking_time_right first_moved_object] = fam_trial ()
        if (strcmp(pos_left,'Object1') == true)
            left_object_name = get_config('Object1');
            right_object_name = get_config('Object2');
        else
            left_object_name = get_config('Object2');
            right_object_name = get_config('Object1');
        end
        
        % randomize move left or right object
        display_order = {'left' 'right'};
        display_order = display_order(randperm(length(display_order)));
        
        first_moved_object = display_order{1};
        
        % move objects out and put them on display
        for (moving_object = display_order)  
            if (strcmp(moving_object,'left') == true)
                % move left object from behind occluder
                
                movement_start_time = GetSecs;
                time_to_move = 1;
                distance = swidth / 4.2;
                while ((GetSecs - movement_start_time) <= time_to_move)
                    % calculate how far it should be moved by the proportion of
                    % the the total move time (1s) and the total distance to be
                    % moved (20% of the screen)
                    displacement = ((GetSecs - movement_start_time) / time_to_move) * distance;

                    draw_stage(left_object_name,...
                               right_object_name,...
                               get_config('OccluderL'),...
                               get_config('OccluderR'),...
                               displacement,...
                               0,...
                               0,...
                               0);
                end
                
                % are we labelling?
                if (get_config('LeftObjectLabel') ~= 0)
                    sound_file = get_config('LeftObjectLabel');
                else
                    sound_file = 0;
                end
                
                looking_time_left = freeze_frame(get_config('FamDuration'), 0, sound_file);
                
                % move left object back behind behind occluder
                
                movement_start_time = GetSecs;
                time_to_move = 1;
                distance = swidth / 4.2;
                while ((GetSecs - movement_start_time) <= time_to_move)
                    % calculate how far it should be moved by the proportion of
                    % the the total move time (1s) and the total distance to be
                    % moved (20% of the screen)
                    displacement = (1 - ((GetSecs - movement_start_time) / time_to_move)) * distance;

                    draw_stage(left_object_name,...
                               right_object_name,...
                               get_config('OccluderL'),...
                               get_config('OccluderR'),...
                               displacement,...
                               0,...
                               0,...
                               0);
                end
            else
                % move right object from behind occluder
                
                movement_start_time = GetSecs;
                time_to_move = 1;
                distance = swidth / 4.2;
                while ((GetSecs - movement_start_time) <= time_to_move)
                    % calculate how far it should be moved by the proportion of
                    % the the total move time (1s) and the total distance to be
                    % moved (20% of the screen)
                    displacement = ((GetSecs - movement_start_time) / time_to_move) * distance;

                    draw_stage(left_object_name,...
                               right_object_name,...
                               get_config('OccluderL'),...
                               get_config('OccluderR'),...
                               0,...
                               displacement,...
                               0,...
                               0);
                end
                
                % are we labelling?
                if (get_config('RightObjectLabel') ~= 0)
                    sound_file = get_config('RightObjectLabel');
                else
                    sound_file = 0;
                end
                
                looking_time_right = freeze_frame(get_config('FamDuration'), 0, sound_file);
                
                % move left object back behind behind occluder
                
                movement_start_time = GetSecs;
                time_to_move = 1;
                distance = swidth / 4.2;
                while ((GetSecs - movement_start_time) <= time_to_move)
                    % calculate how far it should be moved by the proportion of
                    % the the total move time (1s) and the total distance to be
                    % moved (20% of the screen)
                    displacement = (1 - ((GetSecs - movement_start_time) / time_to_move)) * distance;

                    draw_stage(left_object_name,...
                               right_object_name,...
                               get_config('OccluderL'),...
                               get_config('OccluderR'),...
                               0,...
                               displacement,...
                               0,...
                               0);
                end
            end
        end
    end

    % draw_stage
    %
    % draws the two objects with their occluders on the screen
    % each object's displacement variable specifies the amount they are
    % moved left/right (for objects) or up (for occluders)
    function draw_stage (left_object_name, right_object_name, left_occluder_name, right_occluder_name, left_object_displaced, right_object_displaced, left_occluder_displaced, right_occluder_displaced)
        % get LEFT image
        filename = [base_dir 'stimuli/' left_object_name];
        [left_object map alpha] = imread(filename);
        % PNG support
        if ~isempty(regexp(left_object_name, '.*\.png'))
            left_object(:,:,4) = alpha(:,:);
        end
        
        % get RIGHT image
        filename = [base_dir 'stimuli/' right_object_name];
        [right_object map alpha] = imread(filename);
        % PNG support
        if ~isempty(regexp(right_object_name, '.*\.png'))
            right_object(:,:,4) = alpha(:,:);
        end
        
        % get LEFT OCCLUDER image
        filename = [base_dir 'stimuli/' left_occluder_name];
        [left_occluder map alpha] = imread(filename);
        % PNG support
        if ~isempty(regexp(left_occluder_name, '.*\.png'))
            left_occluder(:,:,4) = alpha(:,:);
        end
        
        % get RIGHT OCCLUDER image
        filename = [base_dir 'stimuli/' right_occluder_name];
        [right_occluder map alpha] = imread(filename);
        % PNG support
        if ~isempty(regexp(right_occluder_name, '.*\.png'))
            right_occluder(:,:,4) = alpha(:,:);
        end
        
        left_object_imtext = Screen('MakeTexture', wind, left_object);
        right_object_imtext = Screen('MakeTexture', wind, right_object);
        left_occluder_imtext = Screen('MakeTexture', wind, left_occluder);
        right_occluder_imtext = Screen('MakeTexture', wind, right_occluder);
        
        % set image coordinates
        l_texRect = Screen('Rect', left_object_imtext);
        r_texRect = Screen('Rect', right_object_imtext);
        l_o_texRect = Screen('Rect', left_occluder_imtext);
        r_o_texRect = Screen('Rect', right_occluder_imtext);
        
        % scale image sizes
        scaled_l_texRect = l_texRect' * [get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio')];
        scaled_r_texRect = r_texRect' * [get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio')];
        scaled_l_o_texRect = l_o_texRect' * [get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio')];
        scaled_r_o_texRect = r_o_texRect' * [get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio') get_config('ImageRatio')];
        
        left_l = (swidth / 3) - (scaled_l_texRect(3)/4) - left_object_displaced;
        left_t = (sheight / 2) - (scaled_l_texRect(4)/4) + (sheight / 4);
        left_r = (swidth / 3) + (scaled_l_texRect(3)/4) - left_object_displaced;
        left_b = (sheight / 2) + (scaled_l_texRect(4)/4) + (sheight / 4);
        
        right_l = swidth - (swidth / 3) - (scaled_r_texRect(3)/4) + right_object_displaced;
        right_t = (sheight / 2) - (scaled_r_texRect(4)/4) + (sheight / 4);
        right_r = swidth - (swidth / 3) + (scaled_r_texRect(3)/4) + right_object_displaced;
        right_b = (sheight / 2) + (scaled_r_texRect(4)/4) + (sheight / 4);
        
        left_o_l = (swidth / 3) - (scaled_l_o_texRect(3)/2);
        left_o_t = (sheight / 2) - (scaled_l_o_texRect(4)/2) - left_occluder_displaced + (sheight / 4);
        left_o_r = (swidth / 3) + (scaled_l_o_texRect(3)/2);
        left_o_b = (sheight / 2) + (scaled_l_o_texRect(4)/2) - left_occluder_displaced + (sheight / 4);
        
        right_o_l = swidth - (swidth / 3) - (scaled_r_o_texRect(3)/2);
        right_o_t = (sheight / 2) - (scaled_r_o_texRect(4)/2) - right_occluder_displaced + (sheight / 4);
        right_o_r = swidth - (swidth / 3) + (scaled_r_o_texRect(3)/2);
        right_o_b = (sheight / 2) + (scaled_r_o_texRect(4)/2) - right_occluder_displaced + (sheight / 4);
        
        Screen('DrawTexture', wind, left_object_imtext, [0 0 l_texRect(3) l_texRect(4)], [left_l left_t left_r left_b]);
        Screen('DrawTexture', wind, right_object_imtext, [0 0 r_texRect(3) r_texRect(4)], [right_l right_t right_r right_b]);
        Screen('DrawTexture', wind, left_occluder_imtext, [0 0 l_o_texRect(3) l_o_texRect(4)], [left_o_l left_o_t left_o_r left_o_b]);
        Screen('DrawTexture', wind, right_occluder_imtext, [0 0 r_o_texRect(3) r_o_texRect(4)], [right_o_l right_o_t right_o_r right_o_b]);
        
        Screen('Flip', wind);
        
        % release textures
        Screen('Close', left_object_imtext);
        Screen('Close', right_object_imtext);
        Screen('Close', left_occluder_imtext);
        Screen('Close', right_occluder_imtext);
    end

    function attention_getter ()
        log_msg('Showing attention getter.');
        
        keypress_time_to_release = (get_config('StartDelay') / 1000);
        
        movie = Screen('OpenMovie', wind, [base_dir get_config('StimuliFolder') '/' get_config('AttentionGetter')]);
        
        % Start playback engine:
        Screen('PlayMovie', movie, 1);
        
        % set scale to 0 so it will be calculated
        texRect = 0;
        
        keypress_start = 0;
        % loop indefinitely
        while (1 ~= 2)
            % look for a keypress
            if key_pressed()
                if (keypress_start == 0)
                    % start a keypress
                    keypress_start = GetSecs();
                elseif (GetSecs - keypress_start > keypress_time_to_release)
                    % we have pressed the key for as long as we need to
                    % move on
                    Screen('PlayMovie', movie, 0);
                    Screen('CloseMovie', movie);
                    
                    Screen('Flip', wind);
                    
                    break
                end
            else
                % keypress is over so clear it (it's not cumulative)
                keypress_start = 0;
            end
            
            
            tex = Screen('GetMovieImage', wind, movie);
            
            % restart movie?
            if tex < 0
                %Screen('PlayMovie', movie, 0);
                Screen('SetMovieTimeIndex', movie, 0);
                %Screen('PlayMovie', movie, 1);
            else
                % Draw the new texture immediately to screen:
                if (texRect == 0)
                    texRect = Screen('Rect', tex);
                    
                    % calculate scale factors
                    scale_w = winRect(3) / texRect(3);
                    scale_h = winRect(4) / texRect(4);
                    
                    dstRect = CenterRect(ScaleRect(texRect, scale_w, scale_h), Screen('Rect', wind));
                end
                
                Screen('DrawTexture', wind, tex, [], dstRect);

                % Update display:
                Screen('Flip', wind);
                
                % Release texture:
                Screen('Close', tex);
            end
        end
        
        Screen('Flip', wind);
        log_msg('Attention getter ended');
    end

    function test_attention_getter ()
        log_msg('Showing attention getter before test trial.');
        
        % set stage variables
        if (strcmp(pos_left,'Object1') == true)
            left_object_name = get_config('Object1');
            right_object_name = get_config('Object2');
        else
            left_object_name = get_config('Object2');
            right_object_name = get_config('Object1');
        end
        
        left_occluder_name = get_config('OccluderL');
        right_occluder_name = get_config('OccluderR');
        
        keypress_time_to_release = (get_config('StartDelay') / 1000);
        
        % set loop variables
        keypress_start = 0;
        sound_played = false;
        % strobe a dot on the screen every 500ms, and play a sound
        strobe_time = .5; % seconds

        alternate_time = GetSecs + strobe_time;
        state = 1;
        
        % loop indefinitely
        while (1 ~= 2)
            % look for a keypress
            if key_pressed()
                if (keypress_start == 0)
                    % start a keypress
                    keypress_start = GetSecs();
                elseif (GetSecs - keypress_start > keypress_time_to_release)
                    % we have pressed the key for as long as we need to
                    % move on
                    break
                end
            else
                % keypress is over so clear it (it's not cumulative)
                keypress_start = 0;
            end
            
            % deal with strobe/sound
            if (alternate_time < GetSecs)
                if (state == 1)
                    state = 0;
                else
                    state = 1;
                end
                
                alternate_time = GetSecs + strobe_time;
                
                % if state is On, add the dot to the screen
                if (state == 1)
                    % play sound
                    sound_file = [base_dir get_config('StimuliFolder') '/' get_config('AttentionGetterSound')];
                    log_msg(sprintf('Loading sound from: %s',sound_file));

                    [wav, freq] = wavread(sound_file);
                    wav_data = wav';
                    num_channels = size(wav_data,1);

                    try
                        % Try with the 'freq'uency we wanted:
                        pahandle = PsychPortAudio('Open', [], [], 0, freq, num_channels);
                    catch
                        % Failed. Retry with default frequency as suggested by device:
                        psychlasterror('reset');
                        pahandle = PsychPortAudio('Open', [], [], 0, [], num_channels);
                    end

                    % Fill the audio playback buffer with the audio data 'wavedata':
                    PsychPortAudio('FillBuffer', pahandle, wav_data);

                    % Start audio playback for 'repetitions' repetitions of the sound data,
                    % start it immediately (0) and wait for the playback to start, return onset
                    % timestamp.
                    PsychPortAudio('Start', pahandle, 1, 0, 1);
                    
                    % so we can close it...
                    sound_played = true;
                    
                    Screen('FillOval', wind, [139 9 172], [ (swidth/2)-15, (sheight/2)-15+(sheight/4), (swidth/2) + 15, (sheight/2) + 15 + (sheight/4) ]);
                end
                
                % re-draw stage, with or without dot
                draw_stage(left_object_name,...
                           right_object_name,...
                           left_occluder_name,...
                           right_occluder_name,...
                           0,...
                           0,...
                           0,...
                           0);
            end
        end
        
        if (sound_played == true)
            % Stop sound
            PsychPortAudio('Stop', pahandle);

            % Close the audio device:
            PsychPortAudio('Close', pahandle);
        end
        
        log_msg('Attention getter ended - starting test trial.');
    end

    function add_data (data_key, data_value)
        data(length(data) + 1).key = data_key;
        data(length(data)).value = data_value;
        
        % print to screen
        disp(sprintf('\n# %s: %s\n',data_key,data_value));
    end

    function post_experiment (aborted)
        log_msg('Experiment ended');
        
        ListenChar(0);
        Screen('CloseAll');
        Screen('Preference', 'SuppressAllWarnings', 0);
        
        if (aborted == false)
            % get experimenter comments
            comments = inputdlg('Enter your comments about attentiveness, etc.:','Comments',3);
            
            % create empty structure for results
            results = struct('key',{},'value',{});

            [ year, month, day, hour, minute, sec ] = datevec(now);
            end_time = [num2str(year) '-' num2str(month) '-' num2str(day) ' ' num2str(hour) ':' num2str(minute) ':' num2str(sec) ];

            results(length(results) + 1).key = 'Start Time';
            results(length(results)).value = start_time;
            results(length(results) + 1).key = 'End Time';
            results(length(results)).value = end_time;
            results(length(results) + 1).key = 'Status';

            if (aborted == true)
                results(length(results)).value = 'ABORTED!';
            else
                results(length(results)).value = 'Completed';
            end
            results(length(results) + 1).key = 'Experimenter';
            results(length(results)).value = experimenter;
            results(length(results) + 1).key = 'Subject Code';
            results(length(results)).value = subject_code;
            results(length(results) + 1).key = 'Subject Sex';
            results(length(results)).value = subject_sex;
            results(length(results) + 1).key = 'Subject Age';
            results(length(results)).value = subject_age;
            results(length(results) + 1).key = 'Comments';
            results(length(results)).value = comments{1};

            results(length(results) + 1).key = 'Order Code';
            results(length(results)).value = order_code;
            
            % merge in data
            for (i = 1:length(data))
                results(length(results) + 1).key = data(i).key;
                results(length(results)).value = data(i).value;
            end
            
            % save session file
            filename = [base_dir 'sessions/' subject_code '.txt'];
            log_msg(sprintf('Saving results file to %s',filename));
            WriteStructsToText(filename,results)
        else
            disp('Experiment aborted - results file not saved, but there is a log.');
        end
    end

    function create_log_file ()
        fileID = fopen([base_dir 'logs/' subject_code '-' start_time '.txt'],'w');
        fclose(fileID);
    end

    function log_msg (msg)
        fileID = fopen([base_dir 'logs/' subject_code '-' start_time '.txt'],'a');
        
        [ year, month, day, hour, minute, sec ] = datevec(now);
        timestamp = [num2str(year) '-' num2str(month) '-' num2str(day) ' ' num2str(hour) ':' num2str(minute) ':' num2str(sec) ];
        
        fprintf(fileID,'%s - %s\n',timestamp,msg);
        fclose(fileID);
    end

    function [split,numpieces] = explode(string,delimiters)
        %   Created: Sara Silva (sara@itqb.unl.pt) - 2002.04.30

        if isempty(string) % empty string, return empty and 0 pieces
           split{1}='';
           numpieces=0;

        elseif isempty(delimiters) % no delimiters, return whole string in 1 piece
           split{1}=string;
           numpieces=1;

        else % non-empty string and delimiters, the correct case

           remainder=string;
           i=0;

           while ~isempty(remainder)
                [piece,remainder]=strtok(remainder,delimiters);
                i=i+1;
                split{i}=piece;
           end
           numpieces=i;
        end
    end
end