function [extinput_clipped, extinput, inputends,y, removeremove, indexes, awko] = setinput(arq_connect, savestruc,data_size, svst_t_v) %needs to receive the correct data size so that generateidx may work well
extinput = [];
midremove = [];
awko = [];
inputinput = cell(length(arq_connect.sourcelayer),1);
removeremove = inputinput; 
awk = inputinput; 
inputends = [];
[posidx, velidx] = generateidx(data_size, arq_connect.params.skelldef);
for j = 1:length(arq_connect.sourcelayer)
    foundmysource = false;
    for i = 1:length(savestruc.gas)
        if strcmp(arq_connect.sourcelayer{j}, savestruc.gas(i).name)
            if isempty( svst_t_v.gas(i).bestmatchbyindex)
                error('Wrong computation order. Bestmatch field not yet defined.')
            end
            oldinputends = inputends;
            [inputinput{j},inputends,y, indexes] = longinput( savestruc.gas(i).nodes(:,svst_t_v.gas(i).bestmatchbyindex), arq_connect.q, svst_t_v.gas(i).inputs.input_ends, svst_t_v.gas(i).y,svst_t_v.gas(i).inputs.index);
            %%%check for misalignments of inputends
            if ~isempty(oldinputends)
                if ~all(oldinputends==inputends)
                    error('Misaligned layers. Alignment not yet implemented.')
                end
            end
            removeremove{j} = (svst_t_v.gas(i).whotokill); 
            awk{j} = makeawk(arq_connect.q, svst_t_v.gas(i).inputs.awk);
            foundmysource = true;
        end
    end
    if ~foundmysource        
            if strcmp(arq_connect.layertype, 'pos')
                [inputinput{j},inputends,y, indexes] = longinput(svst_t_v.data(posidx,:), arq_connect.q, svst_t_v.ends, svst_t_v.y, num2cell(1:size(svst_t_v.data,2)));                
                awk{j} = makeawk(arq_connect.q, arq_connect.params.skelldef.awk.pos);
            elseif strcmp(arq_connect.layertype, 'vel')
                [inputinput{j},inputends,y, indexes] = longinput(svst_t_v.data(velidx,:), arq_connect.q, svst_t_v.ends, svst_t_v.y, num2cell(1:size(svst_t_v.data,2)));
                awk{j} = makeawk(arq_connect.q, arq_connect.params.skelldef.awk.vel);
            elseif strcmp(arq_connect.layertype, 'all')
                [inputinput{j},inputends,y, indexes] = longinput(svst_t_v.data, arq_connect.q, svst_t_v.ends, svst_t_v.y, num2cell(1:size(svst_t_v.data,2)));
                awk{j} = makeawk(arq_connect.q, [arq_connect.params.skelldef.awk.pos;  arq_connect.params.skelldef.awk.vel] );
            end
    end
    if isempty(inputinput)
        error(strcat('Unknown layer type:', arq_connect.layertype,'or sourcelayer:',arq_connect.sourcelayer))
    end
end
if length(inputinput)>1
    for i = 1:length(inputinput)
        extinput = cat(1,extinput,inputinput{i}); 
        %%% dealing with possible empty sets::
        if ~isempty(removeremove{i})
            midremove = cat(2,midremove,removeremove{i}); 
        end        
        awko = cat(1,awko,awk{i});
    end
else
    extinput = inputinput{:};
    midremove = removeremove{:};
    awko = awk{:};
end
extinput_clipped= removebaddata(extinput, indexes, midremove, arq_connect.q); 
end
function awk = makeawk(q,inawk)
awk = repmat(inawk,q(1),1);
end
function icli = removebaddata(inp, idxx,rev, qp)
if ~isempty(rev)
    q = qp(1);
    switch length(qp)
        case 1
            p = 0;
            r = 1;
        case 2
            p = qp(2);
            r = 1;
        case 3
            p = qp(2);
            r = qp(3);
    end
    allitems = 1:size(inp,2);
    eliminate = [];
    imax = size(rev,2);
    jmax = size(idxx,2);
    for i = 1:imax
        try 
            currrev = [rev{1,i}{:}];
        catch
            currrev = rev{i};
        end
        try
            jlower = max([1 fix((currrev(1)*.7)/(q*(p+1)*r))-1 ]); 
            jhigher = min([jmax ceil((currrev(end))/(q*(p+1)*r))+1]); % multiply by 10 if it doesnt work %%% there is some irregularity here because of actions that dont end where they should, so each ending action can cause you to drift additionally q*(p+1)*r-1 data samples      
        catch 
            try %% maybe it is still a cell then?
                jlower = max([1 fix((currrev{1}*.9)/(q*(p+1)*r))-1 ]); 
                jhigher = min([jmax ceil((currrev{end})/(q*(p+1)*r))+1]);
            catch
                dbgmsg('Using wide ranges. This will take a while.')
                jlower = 1;
                jhigher = jmax;
            end                       
        end
        for j = jlower:jhigher         
            kmax = size(idxx{j},2);
            for k = 1:kmax                
                curridxx = [idxx{j}{k}{:}];
                if isequal(currrev,curridxx) 
                    if iscell(currrev)
                        eliminate = cat(2, eliminate, [currrev{:}]);
                    else
                        eliminate = cat(2, eliminate, j);
                    end
                elseif (iscell(curridxx)&&length(curridxx)>length(currrev))
                    arryofcurridx = curridxx;
                    while (iscell(arryofcurridx)&&length(arryofcurridx)>length(currrev))
                        arryofcurridx = [curridxx{:}];
                        for mm = 1:length(arryofcurridx);
                            if isequal(currrev,arryofcurridx(mm))
                                eliminate = cat(2, eliminate, j);
                            end
                        end
                    end
                end
            end
        end
    end
    whattoget = setdiff(allitems, eliminate);
    icli = inp(:,whattoget);
    if size(rev,2)<size(unique(eliminate),2)
        disp('Unusual point removal.')
    end
    dbgmsg('Removed', num2str(size(unique(eliminate),2)), ' out of ', num2str(size(inp,2)), ' points!',1)
else
    icli = inp;
end
end
