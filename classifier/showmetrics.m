function showmetrics(cst)
[AA, metricsname] = calculatemetrics(cst);
number_of_metrics = length(metricsname);
for i = 1:length(AA)
    fprintf('For gas with %2.0f nodes and %3.0f epoch(s) - evaluated on the validation set:\n', cst(i).params.nodes, cst(i).params.MAX_EPOCHS )
    %%%choosing gas with highest accuracy on the training set and on last layer    
    for j = 1:number_of_metrics
        [ma, ima] = max((AA{i}(:,5,j,2)));
        [mi, imi] = min((AA{i}(:,5,j,2)));
        meanpre = mean(AA{i}(:,5,j,1));
        stdpre = std(AA{i}(:,5,j,1));
        %%%displaying its real precision on the validation set
        fprintf('\t%s\n ',metricsname{j})
        fprintf('\t\tRange  :\t[%2.2f - %2.2f]%%.\n',AA{i}(imi,5,j,1),AA{i}(ima,5,j,1))
        fprintf('\t\tAverage:\t%2.2f � %2.2f %%\n',meanpre,stdpre)
    end
    fprintf('\n')
end
