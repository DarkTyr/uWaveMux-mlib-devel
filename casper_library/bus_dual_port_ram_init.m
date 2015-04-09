%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://www.kat.ac.za                                                      %
%   Copyright (C) 2013 Andrew Martens                                         %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bus_dual_port_ram_init(blk, varargin)
  log_group = 'bus_dual_port_ram_init_debug';

  clog('entering bus_dual_port_ram_init', {'trace', log_group});
  
  defaults = { ...
    'n_bits', repmat(10, 1, 64), 'bin_pts', repmat(0, 1, 64), ...
    'init_vector', repmat(zeros(8192, 1), 1, 64), ...
    'max_fanout', 3, 'mem_type', 'Distributed memory', ...
    'bram_optimization', 'Speed', ...              %'Speed' 'Area' 
    'async_a', 'off', 'async_b', 'off', 'misc', 'on', ...
    'bram_latency', 1, 'fan_latency', 1, ...
    'addra_register', 'on', 'addra_implementation', 'behavioral', ...
    'dina_register', 'on', 'dina_implementation', 'behavioral', ...
    'wea_register', 'on', 'wea_implementation', 'behavioral', ...
    'ena_register', 'on', 'ena_implementation', 'behavioral', ...
    'addrb_register', 'on', 'addrb_implementation', 'behavioral', ...
    'dinb_register', 'on', 'dinb_implementation', 'behavioral', ...
    'web_register', 'on', 'web_implementation', 'behavioral', ...
    'enb_register', 'on', 'enb_implementation', 'behavioral', ...
  };  
  
  check_mask_type(blk, 'bus_dual_port_ram');

  if same_state(blk, 'defaults', defaults, varargin{:}), return, end
  munge_block(blk, varargin{:});

  xpos = 50; xinc = 80;
  ypos = 50; yinc = 20;

  port_w = 30; port_d = 14;
  rep_w = 50; rep_d = 30;
  bus_expand_w = 50; bus_expand_d = 10;
  bus_create_w = 50; bus_create_d = 10;
  bram_w = 50; bram_d = 50;
  del_w = 30; del_d = 20;

  maxy = 2^15; %Simulink limit

  n_bits                    = get_var('n_bits', 'defaults', defaults, varargin{:});
  bin_pts                   = get_var('bin_pts', 'defaults', defaults, varargin{:});
  init_vector               = get_var('init_vector', 'defaults', defaults, varargin{:});
  bram_latency              = get_var('bram_latency', 'defaults', defaults, varargin{:});
  mem_type                  = get_var('mem_type', 'defaults', defaults, varargin{:});
  bram_optimization         = get_var('bram_optimization', 'defaults', defaults, varargin{:});
  misc                      = get_var('misc', 'defaults', defaults, varargin{:});
  async_a                   = get_var('async_a', 'defaults', defaults, varargin{:});
  async_b                   = get_var('async_b', 'defaults', defaults, varargin{:});
  max_fanout                = get_var('max_fanout', 'defaults', defaults, varargin{:});
  fan_latency               = get_var('fan_latency', 'defaults', defaults, varargin{:});
  addra_register            = get_var('addra_register', 'defaults', defaults, varargin{:});
  addra_implementation      = get_var('addra_implementation', 'defaults', defaults, varargin{:});
  dina_register             = get_var('dina_register', 'defaults', defaults, varargin{:});
  dina_implementation       = get_var('dina_implementation', 'defaults', defaults, varargin{:});
  wea_register              = get_var('wea_register', 'defaults', defaults, varargin{:});
  wea_implementation        = get_var('wea_implementation', 'defaults', defaults, varargin{:});
  ena_register              = get_var('ena_register', 'defaults', defaults, varargin{:});
  ena_implementation        = get_var('ena_implementation', 'defaults', defaults, varargin{:});
  addrb_register            = get_var('addrb_register', 'defaults', defaults, varargin{:});
  addrb_implementation      = get_var('addrb_implementation', 'defaults', defaults, varargin{:});
  dinb_register             = get_var('dinb_register', 'defaults', defaults, varargin{:});
  dinb_implementation       = get_var('dinb_implementation', 'defaults', defaults, varargin{:});
  web_register              = get_var('web_register', 'defaults', defaults, varargin{:});
  web_implementation        = get_var('web_implementation', 'defaults', defaults, varargin{:});
  enb_register              = get_var('enb_register', 'defaults', defaults, varargin{:});
  enb_implementation        = get_var('enb_implementation', 'defaults', defaults, varargin{:});

  delete_lines(blk);

  %default state, do nothing 
  if (n_bits(1) == 0),
    clean_blocks(blk);
    save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values
    clog('exiting bus_dual_port_ram_init', {'trace', log_group});
    return;
  end

  [riv, civ]  = size(init_vector);
  [rnb, cnb]  = size(n_bits);
  [rbp, cbp]  = size(bin_pts);

  if (cnb ~= 1 && cbp ~= 1) && ((civ ~= cnb) || (civ ~= cbp)),
    clog('The number of columns in initialisation vector must match the number of values in binary point and number of bits parameter specifications', {'error', log_group});
    error('The number of columns in initialisation vector must match the number of values in binary point and number of bits parameter specifications');
  end

  %%%%%%%%%%%%%%%
  % input ports %
  %%%%%%%%%%%%%%%

  %The calculations below anticipate how BRAMs are to be configured by the Xilinx tools
  %(as detailed in UG190), explicitly generates these, and attempts to control fanout into
  %these
 
  %if optimizing for Area, do the best we can minimising fanout while still using whole BRAMs
  %fanout for very deep BRAMs will be large
  %TODO this should depend on FPGA architecture
  if strcmp(bram_optimization, 'Area'), 
    if      (riv >= 2^12), max_word_size = 9;
    elseif  (riv >= 2^11), max_word_size = 18;
    else,                  max_word_size = 36;
    end
  %if optimising for Speed, keep splitting word size even if wasting BRAM resources
  else, 
    if      (riv >= 2^15), max_word_size = 1;
    elseif  (riv >= 2^14), max_word_size = 2;
    elseif  (riv >= 2^13), max_word_size = 4;
    elseif  (riv >= 2^12), max_word_size = 9;
    elseif  (riv >= 2^11), max_word_size = 18;
    else,                  max_word_size = 36;
    end
  end
  
  ctiv = 0;

  while (ctiv == 0) || ((ctiv * bram_d) > maxy),

    %if we are going to go beyond Xilinx bounds, double the word width
    if (ctiv * bram_d) > maxy,
      clog(['doubling word size from ', num2str(max_word_size), ' to make space'], log_group);
      if      (max_word_size == 1), max_word_size = 2;
      elseif  (max_word_size == 2), max_word_size = 4;
      elseif  (max_word_size == 4), max_word_size = 9;
      elseif  (max_word_size == 9), max_word_size = 18;
      else,                         max_word_size = 36;
      end %if
    end %if
  
    % translate initialisation matrix based on architecture 
    [translated_init_vecs, result] = doubles2unsigned(init_vector, n_bits, bin_pts, max_word_size);
    if result ~= 0,
      clog('error translating initialisation matrix', {'error', log_group});
      error('error translating initialisation matrix');
    end

    [rtiv, ctiv] = size(translated_init_vecs);
  end %while

  clog([num2str(ctiv), ' brams required'], log_group);

  replication = ceil(ctiv/max_fanout);
  clog(['replication factor of ', num2str(replication), ' required'], log_group);

  if (cnb == 1),
    n_bits  = repmat(n_bits, 1, civ);
    bin_pts = repmat(bin_pts, 1, civ);
  end

  ypos_tmp  = ypos;
  
  ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
  reuse_block(blk, 'addra', 'built-in/inport', ...
    'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;

  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2;
  reuse_block(blk, 'dina', 'built-in/inport', ...
    'Port', '2', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*ctiv/2;
 
  ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
  reuse_block(blk, 'wea', 'built-in/inport', ...
    'Port', '3', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;

  ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
  reuse_block(blk, 'addrb', 'built-in/inport', ...
    'Port', '4', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;

  port_index = 5;
  %if we are using Block RAM, then need ports for dinb and web
  if strcmp(mem_type, 'Block RAM'),
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2;
    reuse_block(blk, 'dinb', 'built-in/inport', ...
      'Port', num2str(port_index), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp  = ypos_tmp + yinc + bus_expand_d*ctiv/2;
    port_index = port_index + 1;    

    ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
    reuse_block(blk, 'web', 'built-in/inport', ...
      'Port', num2str(port_index), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;
    port_index = port_index + 1;    
  end

  % asynchronous A port
  if strcmp(async_a, 'on'),
    ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
    reuse_block(blk, 'ena', 'built-in/inport', ...
      'Port', num2str(port_index), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + yinc + bus_expand_d*replication/2;
    port_index = port_index + 1;
  end

  % asynchronous B port
  if strcmp(async_b, 'on'),
    ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
    reuse_block(blk, 'enb', 'built-in/inport', ...
      'Port', num2str(port_index), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + yinc + bus_expand_d*replication/2;
    port_index = port_index + 1;
  end
  
  %misc port
  if strcmp(misc, 'on'),
    reuse_block(blk, 'misci', 'built-in/inport', ...
      'Port', num2str(port_index), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  end

  xpos      = xpos + xinc + port_w/2;  

  %%%%%%%%%%%%%%%%%%%%
  % replicate inputs %
  %%%%%%%%%%%%%%%%%%%%

  xpos = xpos + rep_w/2;

  ypos_tmp  = ypos; %reset ypos

  % replicate addra
  if strcmp(addra_register, 'on'), latency = fan_latency;
  else, latency = 0;
  end
  ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
  reuse_block(blk, 'rep_addra', 'casper_library_bus/bus_replicate', ...
    'replication', num2str(replication), 'latency', num2str(latency), 'misc', 'off', ... 
    'implementation', addra_implementation, ...
    'Position', [xpos-rep_w/2 ypos_tmp-rep_d/2 xpos+rep_w/2 ypos_tmp+rep_d/2]);
  add_line(blk, 'addra/1', 'rep_addra/1');
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;

  % delay dina
  if strcmp(dina_implementation, 'core'), reg_retiming = 'off';
  else, reg_retiming = 'on';
  end
  
  if strcmp(dina_register, 'on'), latency = fan_latency;
  else, latency = 0;
  end
  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2;
  reuse_block(blk, 'ddina', 'xbsIndex_r4/Delay', ...
    'latency', num2str(latency), 'reg_retiming', reg_retiming, ...
    'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
  add_line(blk, ['dina/1'], 'ddina/1');
  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;

  % replicate wea
  if strcmp(wea_register, 'on'), latency = fan_latency;
  else, latency = 0;
  end
  ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
  reuse_block(blk, 'rep_wea', 'casper_library_bus/bus_replicate', ...
    'replication', num2str(replication), 'latency', num2str(latency), 'misc', 'off', ... 
    'implementation', wea_implementation, ...
    'Position', [xpos-rep_w/2 ypos_tmp-rep_d/2 xpos+rep_w/2 ypos_tmp+rep_d/2]);
  add_line(blk, 'wea/1', 'rep_wea/1'); 
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;

  % replicate addrb
  if strcmp(addrb_register, 'on'), latency = fan_latency;
  else, latency = 0;
  end
  ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
  reuse_block(blk, 'rep_addrb', 'casper_library_bus/bus_replicate', ...
    'replication', num2str(replication), 'latency', num2str(latency), 'misc', 'off', ... 
    'implementation', addrb_implementation, ...
    'Position', [xpos-rep_w/2 ypos_tmp-rep_d/2 xpos+rep_w/2 ypos_tmp+rep_d/2]);
  add_line(blk, 'addrb/1', 'rep_addrb/1'); 
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;

  if strcmp(mem_type, 'Block RAM'),
    % delay dinb
    if strcmp(dinb_implementation, 'core'), reg_retiming = 'off';
    else, reg_retiming = 'on';
    end

    if strcmp(dinb_register, 'on'), latency = fan_latency;
    else, latency = 0;
    end

    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2;
    reuse_block(blk, 'ddinb', 'xbsIndex_r4/Delay', ...
      'latency', num2str(latency), 'reg_retiming', reg_retiming, ...
      'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
    add_line(blk, ['dinb/1'], 'ddinb/1');
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
  
    % replicate web
    if strcmp(web_register, 'on'), latency = fan_latency;
    else, latency = 0;
    end
    ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
    reuse_block(blk, 'rep_web', 'casper_library_bus/bus_replicate', ...
      'replication', num2str(replication), 'latency', num2str(latency), 'misc', 'off', ... 
      'implementation', web_implementation, ...
      'Position', [xpos-rep_w/2 ypos_tmp-rep_d/2 xpos+rep_w/2 ypos_tmp+rep_d/2]);
    add_line(blk, 'web/1', 'rep_web/1'); 
    ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;
  end %if

  if strcmp(async_a, 'on'),
    % replicate ena
    if strcmp(ena_register, 'on'), latency = fan_latency;
    else, latency = 0;
    end
    ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
    reuse_block(blk, 'rep_ena', 'casper_library_bus/bus_replicate', ...
      'replication', num2str(replication), 'latency', num2str(latency), 'misc', 'off', ... 
      'implementation', ena_implementation, ...
      'Position', [xpos-rep_w/2 ypos_tmp-rep_d/2 xpos+rep_w/2 ypos_tmp+rep_d/2]);
    add_line(blk, 'ena/1', 'rep_ena/1'); 
    ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;
  end

  if strcmp(async_b, 'on'),
    % replicate enb
    if strcmp(enb_register, 'on'), latency = fan_latency;
    else, latency = 0;
    end
    ypos_tmp  = ypos_tmp + bus_expand_d*replication/2;
    reuse_block(blk, 'rep_enb', 'casper_library_bus/bus_replicate', ...
      'replication', num2str(replication), 'latency', num2str(latency), 'misc', 'off', ... 
      'implementation', enb_implementation, ...
      'Position', [xpos-rep_w/2 ypos_tmp-rep_d/2 xpos+rep_w/2 ypos_tmp+rep_d/2]);
    add_line(blk, 'enb/1', 'rep_enb/1'); 
    ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;
  end 

  xpos = xpos + xinc + rep_w/2;
  
  %%%%%%%%%%%%%%%%
  % debus inputs %
  %%%%%%%%%%%%%%%%
  
  xpos = xpos + bus_expand_w/2;
 
  % debus addra
  ypos_tmp  = ypos + bus_expand_d*ctiv/2 + yinc;
  reuse_block(blk, 'debus_addra', 'casper_library_flow_control/bus_expand', ...
    'mode', 'divisions of equal size', 'outputNum', num2str(replication), ...
    'outputWidth', mat2str(repmat(ceil(log2(rtiv)), 1, replication)), ...
    'outputBinaryPt', mat2str(zeros(1, replication)), ...
    'outputArithmeticType', mat2str(zeros(1,replication)), 'show_format', 'on', 'outputToWorkspace', 'off', ...
    'variablePrefix', '', 'outputToModelAsWell', 'on', ...
    'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
  ypos_tmp  = ypos_tmp + yinc + bus_expand_d*replication/2;
  add_line(blk, 'rep_addra/1', 'debus_addra/1');
  
  % debus dina
  ypos_tmp        = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
  total_bits      = sum(n_bits);
  extra           = mod(total_bits, max_word_size);
  main            = repmat(max_word_size, 1, floor(total_bits/max_word_size));
  outputWidth     = [main];
  if (extra ~= 0), 
    outputWidth = [extra, outputWidth];   
  end

  reuse_block(blk, 'debus_dina', 'casper_library_flow_control/bus_expand', ...
    'mode', 'divisions of arbitrary size', ...
    'outputWidth', mat2str(outputWidth), 'outputBinaryPt', mat2str(zeros(1, ctiv)), ...
    'outputArithmeticType', mat2str(zeros(1,ctiv)), 'show_format', 'on', 'outputToWorkspace', 'off', ...
    'variablePrefix', '', 'outputToModelAsWell', 'on', ...
    'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
  add_line(blk, 'ddina/1', 'debus_dina/1');

  % debus wea
  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
  reuse_block(blk, 'debus_wea', 'casper_library_flow_control/bus_expand', ...
    'mode', 'divisions of equal size', 'outputNum', num2str(replication), ...
    'outputWidth', mat2str(ones(1, replication)), ...
    'outputBinaryPt', mat2str(zeros(1, replication)), ...
    'outputArithmeticType', mat2str(repmat(2,1,replication)), 'show_format', 'on', 'outputToWorkspace', 'off', ...
    'variablePrefix', '', 'outputToModelAsWell', 'on', ...
    'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
  add_line(blk, 'rep_wea/1', 'debus_wea/1');

  % debus addrb
  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
  reuse_block(blk, 'debus_addrb', 'casper_library_flow_control/bus_expand', ...
    'mode', 'divisions of equal size', 'outputNum', num2str(replication), ...
    'outputWidth', mat2str(repmat(ceil(log2(rtiv)), 1, replication)), ...
    'outputBinaryPt', mat2str(zeros(1, replication)), ...
    'outputArithmeticType', mat2str(zeros(1,replication)), 'show_format', 'on', 'outputToWorkspace', 'off', ...
    'variablePrefix', '', 'outputToModelAsWell', 'on', ...
    'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
  ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
  add_line(blk, 'rep_addrb/1', 'debus_addrb/1');

  if strcmp(mem_type, 'Block RAM'),
    % debus dinb
    ypos_tmp        = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    reuse_block(blk, 'debus_dinb', 'casper_library_flow_control/bus_expand', ...
      'mode', 'divisions of arbitrary size', ...
      'outputWidth', mat2str(outputWidth), 'outputBinaryPt', mat2str(zeros(1, ctiv)), ...
      'outputArithmeticType', mat2str(zeros(1,ctiv)), 'show_format', 'on', 'outputToWorkspace', 'off', ...
      'variablePrefix', '', 'outputToModelAsWell', 'on', ...
      'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    add_line(blk, 'ddinb/1', 'debus_dinb/1');

    % debus web
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    reuse_block(blk, 'debus_web', 'casper_library_flow_control/bus_expand', ...
      'mode', 'divisions of equal size', 'outputNum', num2str(replication), ...
      'outputWidth', mat2str(ones(1, replication)), 'outputBinaryPt', mat2str(zeros(1, replication)), ...
      'outputArithmeticType', mat2str(repmat(2,1,replication)), ...
      'show_format', 'on', 'outputToWorkspace', 'off', 'variablePrefix', '', 'outputToModelAsWell', 'on', ...
      'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    add_line(blk, 'rep_web/1', 'debus_web/1');
  end %if

  if strcmp(async_a, 'on'),
    % debus ena 
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    reuse_block(blk, 'debus_ena', 'casper_library_flow_control/bus_expand', ...
      'mode', 'divisions of equal size', 'outputNum', num2str(replication), ...
      'outputWidth', mat2str(ones(1, replication)), 'outputBinaryPt', mat2str(zeros(1, replication)), ...
      'outputArithmeticType', mat2str(repmat(2,1,replication)), ...
      'show_format', 'on', 'outputToWorkspace', 'off', 'variablePrefix', '', 'outputToModelAsWell', 'on', ...
      'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    add_line(blk, 'rep_ena/1', 'debus_ena/1');
  end 
 
  if strcmp(async_b, 'on'),
    % debus enb 
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    reuse_block(blk, 'debus_enb', 'casper_library_flow_control/bus_expand', ...
      'mode', 'divisions of equal size', 'outputNum', num2str(replication), ...
      'outputWidth', mat2str(ones(1, replication)), 'outputBinaryPt', mat2str(zeros(1, replication)), ...
      'outputArithmeticType', mat2str(repmat(2,1,replication)), ...
      'show_format', 'on', 'outputToWorkspace', 'off', 'variablePrefix', '', 'outputToModelAsWell', 'on', ...
      'Position', [xpos-bus_expand_w/2 ypos_tmp-bus_expand_d*ctiv/2 xpos+bus_expand_w/2 ypos_tmp+bus_expand_d*ctiv/2]);
    ypos_tmp  = ypos_tmp + bus_expand_d*ctiv/2 + yinc;
    add_line(blk, 'rep_enb/1', 'debus_enb/1');
  end 

  if strcmp(misc, 'on'),
    % delay misc
    ypos_tmp = ypos_tmp + del_d/2;
    reuse_block(blk, 'dmisc0', 'xbsIndex_r4/Delay', ...
      'latency', num2str(fan_latency), 'reg_retiming', 'on', ...
      'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
    ypos_tmp = ypos_tmp + yinc + del_d/2;
    add_line(blk, 'misci/1', 'dmisc0/1');
  end

  xpos = xpos + xinc + bus_expand_w/2;

  %%%%%%%%%%%%%%
  % bram layer %
  %%%%%%%%%%%%%%
  
  ypos_tmp  = ypos;
  xpos      = xpos + xinc + bram_w/2;

  for bram_index = 1:ctiv,

    % bram self

    % because the string version of the initVector could be too long (Matlab has upper limits on the length of strings), 
    % we save the values in the UserData parameter of the dual port ram block (available on all Simulink blocks it seems)
    % and then reference that value from the mask

    initVector = translated_init_vecs(:, bram_index)';
    UserData = struct('initVector', double(initVector));

    if strcmp(bram_optimization, 'Speed'), optimize = 'Speed';
    else, optimize = 'Area';
    end

    ypos_tmp  = ypos_tmp + bram_d/2; 
    bram_name = ['bram', num2str(bram_index-1)];
    reuse_block(blk, bram_name, 'xbsIndex_r4/Dual Port RAM', ...
      'UserData', UserData, 'UserDataPersistent', 'on', ...
      'depth', num2str(rtiv), 'initVector', ['zeros( 1, ',num2str(rtiv),')'], ...
      'write_mode_A', 'Read Before Write', 'write_mode_B', 'Read Before Write', ...
      'en_a', async_a, 'en_b', async_b, 'optimize', optimize, ...
      'distributed_mem', mem_type, 'latency', num2str(bram_latency), ...
      'Position', [xpos-bram_w/2 ypos_tmp-bram_d/2 xpos+bram_w/2 ypos_tmp+bram_d/2]);
    ypos_tmp  = ypos_tmp + yinc + bram_d/2; 
   
    set_param([blk,'/',bram_name], 'initVector', 'getfield(get_param(gcb, ''UserData''), ''initVector'')');

    % bram connections to replication and debus blocks
    rep_index = mod(bram_index-1, replication) + 1; %replicated index to use
    add_line(blk, ['debus_addra/', num2str(rep_index)], [bram_name, '/1']);
    add_line(blk, ['debus_dina/', num2str(bram_index)], [bram_name, '/2']);
    add_line(blk, ['debus_wea/', num2str(rep_index)], [bram_name, '/3']);
    add_line(blk, ['debus_addrb/', num2str(rep_index)], [bram_name, '/4']);

    port_index = 4;
    if strcmp(mem_type, 'Block RAM'),
      add_line(blk, ['debus_dinb/', num2str(bram_index)], [bram_name, '/5']);
      add_line(blk, ['debus_web/', num2str(rep_index)], [bram_name, '/6']);
      port_index = 6;
    end %if
  
    if strcmp(async_a, 'on'), 
      port_index = port_index+1;
      add_line(blk, ['debus_ena/', num2str(rep_index)], [bram_name, '/', num2str(port_index)]);
    end %if 

    if strcmp(async_b, 'on'), 
      port_index = port_index+1;
      add_line(blk, ['debus_enb/', num2str(rep_index)], [bram_name, '/', num2str(port_index)]);
    end %if 
  end %for 

  % delay for enables and misc

  if strcmp(async_a, 'on'),
    ypos_tmp = ypos_tmp + del_d/2;
    reuse_block(blk, 'dena', 'xbsIndex_r4/Delay', ...
      'latency', num2str(bram_latency), 'reg_retiming', 'on', ...
      'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
    ypos_tmp = ypos_tmp + yinc + del_d/2;
    add_line(blk, ['debus_ena/',num2str(replication)], 'dena/1');
  end;
  
  if strcmp(async_b, 'on'),
    ypos_tmp = ypos_tmp + del_d/2;
    reuse_block(blk, 'denb', 'xbsIndex_r4/Delay', ...
      'latency', num2str(bram_latency), 'reg_retiming', 'on', ...
      'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
    ypos_tmp = ypos_tmp + yinc + del_d/2;
    add_line(blk, ['debus_enb/1'], 'denb/1');
  end %if

  if strcmp(misc, 'on'),
    ypos_tmp = ypos_tmp + del_d/2;
    reuse_block(blk, 'dmisc1', 'xbsIndex_r4/Delay', ...
      'latency', num2str(bram_latency), 'reg_retiming', 'on', ...
      'Position', [xpos-del_w/2 ypos_tmp-del_d/2 xpos+del_w/2 ypos_tmp+del_d/2]);
    ypos_tmp = ypos_tmp + yinc + del_d/2;
    add_line(blk, 'dmisc0/1', 'dmisc1/1');
  end %if
   
  xpos = xpos + xinc + bram_w/2;

  %%%%%%%%%%%%%%%%%%%%%%%%%%
  % recombine bram outputs %
  %%%%%%%%%%%%%%%%%%%%%%%%%%

  xpos      = xpos + bus_create_w/2;
  ypos_tmp  = ypos; 
 
  ypos_tmp = ypos_tmp + bus_create_d*ctiv/2; 
  reuse_block(blk, 'A_bussify', 'casper_library_flow_control/bus_create', ...
    'inputNum', num2str(ctiv), ...
    'Position', [xpos-bus_create_w/2 ypos_tmp-bus_create_d*ctiv/2 xpos+bus_create_w/2 ypos_tmp+bus_create_d*ctiv/2]);
  ypos_tmp = ypos_tmp + yinc + bus_create_d*ctiv/2; 
 
  ypos_tmp = ypos_tmp + bus_create_d*ctiv/2; 
  reuse_block(blk, 'B_bussify', 'casper_library_flow_control/bus_create', ...
    'inputNum', num2str(ctiv), ...
    'Position', [xpos-bus_create_w/2 ypos_tmp-bus_create_d*ctiv/2 xpos+bus_create_w/2 ypos_tmp+bus_create_d*ctiv/2]);
  ypos_tmp = ypos_tmp + yinc + bus_create_d*ctiv/2; 
  
  for index = 1:ctiv,
    add_line(blk, ['bram',num2str(index-1),'/1'], ['A_bussify', '/', num2str(index)]); 
    add_line(blk, ['bram',num2str(index-1),'/2'], ['B_bussify', '/', num2str(index)]); 
  end %for

  xpos = xpos + xinc + bus_create_w/2;

  %%%%%%%%%%%%%%%%
  % output ports %
  %%%%%%%%%%%%%%%%

  xpos      = xpos + port_w/2;
  ypos_tmp  = ypos; 
 
  ypos_tmp = ypos_tmp + bus_create_d*ctiv/2; 
  reuse_block(blk, 'A', 'built-in/outport', ...
    'Port', '1', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc + bus_create_d*ctiv/2; 
  add_line(blk, 'A_bussify/1', 'A/1');

  ypos_tmp = ypos_tmp + bus_create_d*ctiv/2; 
  reuse_block(blk, 'B', 'built-in/outport', ...
    'Port', '2', 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
  ypos_tmp = ypos_tmp + yinc + bus_create_d*ctiv/2; 
  add_line(blk, 'B_bussify/1', 'B/1');
  
  port_index = 3;
  if strcmp(async_a, 'on'),
    ypos_tmp  = ypos_tmp + port_d/2;
    reuse_block(blk, 'dvalida', 'built-in/outport', ...
      'Port', num2str(port_index), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + yinc + port_d/2;  
    port_index = port_index + 1;
    add_line(blk, 'dena/1', 'dvalida/1');
  end
  
  if strcmp(async_b, 'on'),
    ypos_tmp  = ypos_tmp + port_d/2;
    reuse_block(blk, 'dvalidb', 'built-in/outport', ...
      'Port', num2str(port_index), 'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp = ypos_tmp + yinc + port_d/2;  
    port_index = port_index + 1;
    add_line(blk, 'denb/1', 'dvalidb/1');
  end

  if strcmp(misc, 'on'),
    ypos_tmp  = ypos_tmp + port_d/2;
    reuse_block(blk, 'misco', 'built-in/outport', ...
      'Port', num2str(port_index), ... 
      'Position', [xpos-port_w/2 ypos_tmp-port_d/2 xpos+port_w/2 ypos_tmp+port_d/2]);
    ypos_tmp  = ypos_tmp + yinc + port_d/2;

    add_line(blk, 'dmisc1/1', 'misco/1');
  end

  % When finished drawing blocks and lines, remove all unused blocks.
  clean_blocks(blk);

  save_state(blk, 'defaults', defaults, varargin{:});  % Save and back-populate mask parameter values

  clog('exiting bus_dual_port_ram_init', {'trace', log_group});

end %function bus_dual_port_ram_init
