//*****Post Results****************

    printf("\n|--------------------------------");
    printf("|------------------------------|\n|    c0    |    c1    |    c2    ");
    printf("|   tUI    |   EH   |    EW    |\n|--------------------------------");
    printf("|------------------------------|\n");


    //Print Body
    for a=1:size(results, 2),
        printf("|%7.5f |%.5f |%.5f |", results(1,a), results(2,a), results(3,a));
        printf(" %.2fps | %0.3fV | %6.2fps |\n", results(4,a)*1e12, results(5,a), results(6,a)*1e12);
    end

    printf("|-----");
    printf("|------------------------------|\n");




