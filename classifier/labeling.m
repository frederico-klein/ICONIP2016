function labels = labeling(nodes, data, y)
dbgmsg('Applying labels to nodes.',1)
try
    [~,ni] = pdist2(data',nodes', 'euclidean', 'Smallest',1);
    labels = y(:,ni);
catch
    [labels, ~ ]= labelling(nodes, data, y);
end
end
function [labels, ni1 ]= labelling(nodes, data, y)
maxmax = size(nodes,2);
labels = zeros(1,maxmax);
for i = 1:maxmax
    [~, ~, ni1 , ~ , ~] = findnearest(nodes(:,i), data); 
    labels(i) = y(ni1);
end
end