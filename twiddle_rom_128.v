module twiddle_rom_128 (
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire        [6:0]  addr,
    output wire               out_valid,
    output wire signed [15:0] tw_re,
    output wire signed [15:0] tw_im
);

    reg [31:0] coeff_rom [0:127];
    wire [31:0] coeff;

    initial begin
        coeff_rom[ 0] = { 16'sd32767,  16'sd00000};
        coeff_rom[ 1] = { 16'sd32729, -16'sd01608};
        coeff_rom[ 2] = { 16'sd32610, -16'sd03212};
        coeff_rom[ 3] = { 16'sd32413, -16'sd04808};
        coeff_rom[ 4] = { 16'sd32138, -16'sd06393};
        coeff_rom[ 5] = { 16'sd31786, -16'sd07962};
        coeff_rom[ 6] = { 16'sd31357, -16'sd09512};
        coeff_rom[ 7] = { 16'sd30853, -16'sd11039};
        coeff_rom[ 8] = { 16'sd30274, -16'sd12540};
        coeff_rom[ 9] = { 16'sd29622, -16'sd14010};
        coeff_rom[10] = { 16'sd28899, -16'sd15447};
        coeff_rom[11] = { 16'sd28106, -16'sd16846};
        coeff_rom[12] = { 16'sd27246, -16'sd18205};
        coeff_rom[13] = { 16'sd26320, -16'sd19520};
        coeff_rom[14] = { 16'sd25330, -16'sd20788};
        coeff_rom[15] = { 16'sd24279, -16'sd22006};
        coeff_rom[16] = { 16'sd23170, -16'sd23170};
        coeff_rom[17] = { 16'sd22006, -16'sd24279};
        coeff_rom[18] = { 16'sd20788, -16'sd25330};
        coeff_rom[19] = { 16'sd19520, -16'sd26320};
        coeff_rom[20] = { 16'sd18205, -16'sd27246};
        coeff_rom[21] = { 16'sd16846, -16'sd28106};
        coeff_rom[22] = { 16'sd15447, -16'sd28899};
        coeff_rom[23] = { 16'sd14010, -16'sd29622};
        coeff_rom[24] = { 16'sd12540, -16'sd30274};
        coeff_rom[25] = { 16'sd11039, -16'sd30853};
        coeff_rom[26] = { 16'sd09512, -16'sd31357};
        coeff_rom[27] = { 16'sd07962, -16'sd31786};
        coeff_rom[28] = { 16'sd06393, -16'sd32138};
        coeff_rom[29] = { 16'sd04808, -16'sd32413};
        coeff_rom[30] = { 16'sd03212, -16'sd32610};
        coeff_rom[31] = { 16'sd01608, -16'sd32729};
        coeff_rom[32] = { 16'sd00000,  16'sh8000};
        coeff_rom[33] = {-16'sd01608, -16'sd32729};
        coeff_rom[34] = {-16'sd03212, -16'sd32610};
        coeff_rom[35] = {-16'sd04808, -16'sd32413};
        coeff_rom[36] = {-16'sd06393, -16'sd32138};
        coeff_rom[37] = {-16'sd07962, -16'sd31786};
        coeff_rom[38] = {-16'sd09512, -16'sd31357};
        coeff_rom[39] = {-16'sd11039, -16'sd30853};
        coeff_rom[40] = {-16'sd12540, -16'sd30274};
        coeff_rom[41] = {-16'sd14010, -16'sd29622};
        coeff_rom[42] = {-16'sd15447, -16'sd28899};
        coeff_rom[43] = {-16'sd16846, -16'sd28106};
        coeff_rom[44] = {-16'sd18205, -16'sd27246};
        coeff_rom[45] = {-16'sd19520, -16'sd26320};
        coeff_rom[46] = {-16'sd20788, -16'sd25330};
        coeff_rom[47] = {-16'sd22006, -16'sd24279};
        coeff_rom[48] = {-16'sd23170, -16'sd23170};
        coeff_rom[49] = {-16'sd24279, -16'sd22006};
        coeff_rom[50] = {-16'sd25330, -16'sd20788};
        coeff_rom[51] = {-16'sd26320, -16'sd19520};
        coeff_rom[52] = {-16'sd27246, -16'sd18205};
        coeff_rom[53] = {-16'sd28106, -16'sd16846};
        coeff_rom[54] = {-16'sd28899, -16'sd15447};
        coeff_rom[55] = {-16'sd29622, -16'sd14010};
        coeff_rom[56] = {-16'sd30274, -16'sd12540};
        coeff_rom[57] = {-16'sd30853, -16'sd11039};
        coeff_rom[58] = {-16'sd31357, -16'sd09512};
        coeff_rom[59] = {-16'sd31786, -16'sd07962};
        coeff_rom[60] = {-16'sd32138, -16'sd06393};
        coeff_rom[61] = {-16'sd32413, -16'sd04808};
        coeff_rom[62] = {-16'sd32610, -16'sd03212};
        coeff_rom[63] = {-16'sd32729, -16'sd01608};
        coeff_rom[64] = { 16'sh8000,  16'sd00000};
        coeff_rom[65] = {-16'sd32729,  16'sd01608};
        coeff_rom[66] = {-16'sd32610,  16'sd03212};
        coeff_rom[67] = {-16'sd32413,  16'sd04808};
        coeff_rom[68] = {-16'sd32138,  16'sd06393};
        coeff_rom[69] = {-16'sd31786,  16'sd07962};
        coeff_rom[70] = {-16'sd31357,  16'sd09512};
        coeff_rom[71] = {-16'sd30853,  16'sd11039};
        coeff_rom[72] = {-16'sd30274,  16'sd12540};
        coeff_rom[73] = {-16'sd29622,  16'sd14010};
        coeff_rom[74] = {-16'sd28899,  16'sd15447};
        coeff_rom[75] = {-16'sd28106,  16'sd16846};
        coeff_rom[76] = {-16'sd27246,  16'sd18205};
        coeff_rom[77] = {-16'sd26320,  16'sd19520};
        coeff_rom[78] = {-16'sd25330,  16'sd20788};
        coeff_rom[79] = {-16'sd24279,  16'sd22006};
        coeff_rom[80] = {-16'sd23170,  16'sd23170};
        coeff_rom[81] = {-16'sd22006,  16'sd24279};
        coeff_rom[82] = {-16'sd20788,  16'sd25330};
        coeff_rom[83] = {-16'sd19520,  16'sd26320};
        coeff_rom[84] = {-16'sd18205,  16'sd27246};
        coeff_rom[85] = {-16'sd16846,  16'sd28106};
        coeff_rom[86] = {-16'sd15447,  16'sd28899};
        coeff_rom[87] = {-16'sd14010,  16'sd29622};
        coeff_rom[88] = {-16'sd12540,  16'sd30274};
        coeff_rom[89] = {-16'sd11039,  16'sd30853};
        coeff_rom[90] = {-16'sd09512,  16'sd31357};
        coeff_rom[91] = {-16'sd07962,  16'sd31786};
        coeff_rom[92] = {-16'sd06393,  16'sd32138};
        coeff_rom[93] = {-16'sd04808,  16'sd32413};
        coeff_rom[94] = {-16'sd03212,  16'sd32610};
        coeff_rom[95] = {-16'sd01608,  16'sd32729};
        coeff_rom[96] = { 16'sd00000,  16'sd32767};
        coeff_rom[97] = { 16'sd01608,  16'sd32729};
        coeff_rom[98] = { 16'sd03212,  16'sd32610};
        coeff_rom[99] = { 16'sd04808,  16'sd32413};
        coeff_rom[100] = { 16'sd06393,  16'sd32138};
        coeff_rom[101] = { 16'sd07962,  16'sd31786};
        coeff_rom[102] = { 16'sd09512,  16'sd31357};
        coeff_rom[103] = { 16'sd11039,  16'sd30853};
        coeff_rom[104] = { 16'sd12540,  16'sd30274};
        coeff_rom[105] = { 16'sd14010,  16'sd29622};
        coeff_rom[106] = { 16'sd15447,  16'sd28899};
        coeff_rom[107] = { 16'sd16846,  16'sd28106};
        coeff_rom[108] = { 16'sd18205,  16'sd27246};
        coeff_rom[109] = { 16'sd19520,  16'sd26320};
        coeff_rom[110] = { 16'sd20788,  16'sd25330};
        coeff_rom[111] = { 16'sd22006,  16'sd24279};
        coeff_rom[112] = { 16'sd23170,  16'sd23170};
        coeff_rom[113] = { 16'sd24279,  16'sd22006};
        coeff_rom[114] = { 16'sd25330,  16'sd20788};
        coeff_rom[115] = { 16'sd26320,  16'sd19520};
        coeff_rom[116] = { 16'sd27246,  16'sd18205};
        coeff_rom[117] = { 16'sd28106,  16'sd16846};
        coeff_rom[118] = { 16'sd28899,  16'sd15447};
        coeff_rom[119] = { 16'sd29622,  16'sd14010};
        coeff_rom[120] = { 16'sd30274,  16'sd12540};
        coeff_rom[121] = { 16'sd30853,  16'sd11039};
        coeff_rom[122] = { 16'sd31357,  16'sd09512};
        coeff_rom[123] = { 16'sd31786,  16'sd07962};
        coeff_rom[124] = { 16'sd32138,  16'sd06393};
        coeff_rom[125] = { 16'sd32413,  16'sd04808};
        coeff_rom[126] = { 16'sd32610,  16'sd03212};
        coeff_rom[127] = { 16'sd32729,  16'sd01608};
    end

    assign coeff = coeff_rom[addr];
    assign out_valid = rst_n & in_valid;
    assign tw_re = out_valid ? coeff[31:16] : 16'sd0;
    assign tw_im = out_valid ? coeff[15:0]  : 16'sd0;

endmodule
