function ula = antPrep(num_elements, c, fc)
lambda = c / fc; % wavelength
d = lambda/2; % spacsing antenna elemnts
dia = dielectric;
pm = patchMicrostrip;
patchElement = design(pm,fc);
patchElement.Substrate=dia;
patchElement.Tilt = 90;
patchElement.TiltAxis = [0 1 0];
ula = phased.ULA('Element', patchElement, 'NumElements',num_elements,'ElementSpacing',d);

