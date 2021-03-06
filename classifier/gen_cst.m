function metrics = gen_cst(b)
metrics(length(b),length(b(1).mt)) = struct; 
for ii = 1:length(b)
    for jj= 1:length(b(ii).mt)
        metrics(ii,jj).conffig = b(ii).mt(jj).conffig;
        metrics(ii,jj).val = b(ii).mt(jj).confusions.val;
        metrics(ii,jj).train = b(ii).mt(jj).confusions.train;
        if ~isfield(b(ii).mt(jj).outparams, 'accumulatedepochs')
            metrics(ii,jj).accumulatedepochs = paramsZ(ii).MAX_EPOCHS;
        else
            metrics(ii,jj).accumulatedepochs = b(ii).mt(jj).outparams.accumulatedepochs;
        end
    end
end