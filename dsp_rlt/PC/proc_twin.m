function [twinu, twind] = proc_twin(nbar, sll, Ns)
    twinu = taylorwin(Ns, nbar, sll);
    twind = taylorwin(Ns, nbar, sll);
end