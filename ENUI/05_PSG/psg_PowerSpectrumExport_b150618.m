function psg_PowerSpectrumExport(handles)
%----------------------------------------------------------
% Pwer Spectrum Stage
%
%
% Author : Gwan-Taek Lee
% Last update : 2012. 02. 05.
%----------------------------------------------------------

parms = inputdlg({'Frequency Range (Hz) - Min Max;',...
                    'FFT Window Length (sec)'...,
                    'Suffix'},'',1,...
                    {'1 3;4 7;8 12;13 30;30 45;','3','_Power'});
                
path = uigetdir;                
                
if ~isempty(parms) && ~isequal(path,0)
    
    % Prepare Input Parameter======================================
    fband    = gui_GetParms(parms{1}, '%f %f', ';');
    win      = gui_GetParms(parms{2}, '%f', ' ');
    suffix   = parms{3};
    path     = [path '/'];
    
    % Prepare spectra data=========================================
    selitem = handles.i_file;
    perc    = 0.5; % overlap percentage
    
    Head    = handles.Head(selitem);
    Data    = file_Load(Head.FileName, Head.FilePath, 'Data');
    Data    = util_DataReference(Data, Head.RefeChan);
    
    i_chan  = Head.DataChan;
    
    [P F]   = psg_PowerSpectrum(Head,Data(i_chan,:),win,perc);
    P       = mean(P,4); % Mean Segments in a epoch
    
    fmax = util_GetIndex(F,55);
    tot = repmat(sum(P(:,1:fmax,:),2), [1 size(P,2) 1]);
    R = P ./ tot;  % Relative
    A = P;         % Absolute    
%     Z = zscore(P,0,3);  % Z-Score
    Z = zscore(P,0);  % Z-Score `150401 bug fix - 버전이 다른듯 
    
    % Prepare File write===========================================
    i_fband  = util_GetIndex(F, fband);
    n_chan   = length(i_chan);
    n_epch   = length(Head.Stage.Time);
    n_fband  = size(i_fband, 1);
    
    % Prepare matrix
    out = cell(n_chan*n_fband*n_epch,8);
	out(1,1) = {'Channel'};
    out(1,2) = {'Frequency'};
    out(1,3) = {'Epoch'};
    out(1,4) = {'Time'};
    out(1,5) = {'Stage'};
    out(1,6) = {'Absolute'};
    out(1,7) = {'Relative'};
    out(1,8) = {'Z-Score'};
        
    pt = 2;
    % Spectra Series
    for c = 1 : n_chan
        for b = 1 : n_fband
            for e = 1 : n_epch
                out(pt,1) = Head.ChanLabel(c);
                out(pt,2) = {[num2str(fband(b,1)) '-' num2str(fband(b,2)) 'Hz']};
                out(pt,3) = {num2str(e)};
                out(pt,4) = {datestr(Head.Stage.Time(e))};
                if 0 == max(~isnan(Head.Stage.Series(e,:))) % debug
                    Head.Stage.Series(e,1) = 1 ; 
                end
                out(pt,5) = Head.Stage.Label(~isnan(Head.Stage.Series(e,:)));  %error
                out(pt,6) = {squeeze(mean(A(c,i_fband(b,1):i_fband(b,2),e),2))};
                out(pt,7) = {squeeze(mean(R(c,i_fband(b,1):i_fband(b,2),e),2))};
                out(pt,8) = {squeeze(mean(Z(c,i_fband(b,1):i_fband(b,2),e),2))};
                pt = pt + 1;
            end
        end
    end
    
    % Write xls
%     xlswrite([path strtok(Head.FileName,'.') suffix '.xls'], out);
%   `150401 용량이 많아 안되는 것 같아 임시로 시트를 나눠봤는데 됨
%   `150401 결과값을 어떻게 내는지 더 이해하게 되면 특정 기준으로 나누겠음
    helf_sheet = fix(length(out)/2); % end/2 이런식으로하면 소숫점 생길거같아서
    xlswrite([path strtok(Head.FileName,'.') suffix '.xls'], out(1:helf_sheet,:), 1);
    xlswrite([path strtok(Head.FileName,'.') suffix '.xls'], [out(1,:) ; out(helf_sheet+1:end,:)], 2);
end