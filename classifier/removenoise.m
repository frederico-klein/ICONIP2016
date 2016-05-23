function allkill = removenoise(nodes, data, oldwhotokill, gamma, indexes)
activations = exp(-pdist2(nodes',data','euclidean','Smallest',1));
meana = mean(activations);
stda = std(activations);
if ~iscell(oldwhotokill)
    oldwhotokill = num2cell(oldwhotokill);
end
whotokill = setdiff((activations<(meana-gamma*stda)).*(1:size(activations,2)),0);
allkill = [indexes(whotokill), oldwhotokill{:}];
end