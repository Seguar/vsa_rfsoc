function ula = antPrep(num_elements, c, fc)
lambda = c / fc; % wavelength
d = lambda/2; % spacsing antenna elemnts
ula = phased.ULA('NumElements',num_elements,'ElementSpacing',d);