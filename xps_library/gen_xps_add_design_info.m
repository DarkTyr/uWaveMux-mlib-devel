function gen_xps_add_design_info(sysname, mssge_paths, slash)
    clog('entering gen_xps_add_design_info','trace');

    %%%%%%%%%%%%%%%%%%%%%%%
    % Add your tag here if you want it to be exported to the boffile design info
    tag_list = {'xps:xsg', ...
        'xps:qdr', ...
        'xps:katadc', ...
        'xps:sw_reg', ...
        'xps:bram', ...
        'xps:tengbe', ...
        'xps:tengbe_v2', ...
        'casper:fft_wideband_real', ...
        'casper:fft', ...
        'casper:snapshot', ...
        'casper:bitsnap', ...
        'casper:pfb_fir', ...
        'casper:pfb_fir_async', ...
        'casper:pfb_fir_real', ...
        'casper:xeng', ...
        'casper:vacc', ...
        'casper:info'};
    %index = find(not(cellfun('isempty', strfind(tag_list, s))));
    %%%%%%%%%%%%%%%%%%%%%%%
    
    % exit if the right classes aren't found
    if exist('design_info.Register', 'class') ~= 8,
        error('no design_info class support found');
        %clog('exiting gen_xps_add_design_info - no design_info class support.', 'trace');
        %return
    end
    
    % check that we can write the file before we do anything
    info_table_filename = 'design_info.tab';
    % paths
    info_table_path = [mssge_paths.xps_path, slash, info_table_filename];
    try
        fid = fopen(info_table_path, 'w');
        fprintf(fid, '');
    catch e
        error(['Could not open ', info_table_path, '.']);
    end
    fclose(fid);
    
    % find all objects in the tag list
    tagged_objects = {};
    for ctr = 1 : numel(tag_list),
        tag = tag_list{ctr};
        blks = find_system(sysname, 'FollowLinks', 'on', 'LookUnderMasks', 'all', 'Tag', tag);
        for b = 1 : numel(blks),
            tagged_objects = [tagged_objects, blks{b}];
        end
    end
    
    % write the coreinfo table file
    design_info.write_info_table(info_table_path, sysname, tagged_objects)

    clog('exiting gen_xps_add_design_info','trace');
end % end function gen_xps_add_design_info