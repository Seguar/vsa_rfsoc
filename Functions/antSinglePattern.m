function p = antSinglePattern(fc, scan_axis)
dia = dielectric;
pm = patchMicrostrip;
patchElement = design(pm,fc);
patchElement.Substrate=dia;
patchElement.Tilt = 90;
patchElement.TiltAxis = [0 1 0];
p = pattern(patchElement,fc,scan_axis, 0,'Type','gain','CoordinateSystem','polar',...
    'Normalize',false);
p = db2pow(p);
% p = p + max(p);
p = p/max(p);
p = 1./p;