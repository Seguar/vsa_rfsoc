function vsaSetup(setupFile)
if not(isempty(instrfind))
    delete(instrfind)
end
format long g
pcvsa = visa('keysight', 'TCPIP0::localhost::hislip_vsa0::INSTR');
fopen(pcvsa)
fprintf(pcvsa, sprintf(':MMEMory:LOAD:SETup "%s"', setupFile));