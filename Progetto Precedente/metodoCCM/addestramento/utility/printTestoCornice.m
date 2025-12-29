function printTestoCornice(testo,car)

    lunghezza = strlength(testo) + 2; 
    disp(newline);

    if car == '+'
        fprintf('+%s+\n', repmat('-', 1, lunghezza));
        fprintf('| %s |\n', testo);
        fprintf('+%s+\n', repmat('-', 1, lunghezza));
    end

    if car == '*'
        fprintf('*%s*\n', repmat('*', 1, lunghezza));
        fprintf('* %s *\n', testo);
        fprintf('*%s*\n', repmat('*', 1, lunghezza));
    end

end

