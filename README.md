# FFT 128 điểm

| Tên | Nhiệm vụ |
|---|---|
| Khang | Code các module, thiết kế datapath, thiết kế DMA. |
| Huy | Code controller + bọc Avalon bus, thiết kế testbench kiểm tra kết quả, code phần mềm điều khiển. |


Mở `FFT_128.qpf` trong Quartus. Module top level là `fft128_datapath`. Input đầu vào chỉ nhận số thực 16 bit. Dữ liệu Q8.8 có dấu, mỗi thành phần rộng 16 bit. Từ stage 2 đến stage 7, mỗi mẫu phức được đóng gói thành `{re[15:0], im[15:0]}`. 

## Các file trong project

| File | Input | Output | Chức năng |
|---|---|---|---|
| `fft128_datapath.v` | `clk`, `rst_n`, mẫu thực `data_in` Q8.8, tín hiệu chọn mux, cộng/trừ, xoay và số mũ twiddle | `y_re`, `y_im` Q8.8 | Nối 7 stage theo thứ tự và lấy kết quả ở stage 7. |
| `fft_stage.v` | Mẫu thực 16 bit, `clk`, `rst_n`, `sel_mux`, `sel_add`, `rot_mode` | Hai thành phần 16 bit | Stage 1 với hai SR dài 64, butterfly và xoay đơn giản. |
| `sff_complex_butterfly.v` | Mẫu phức 32 bit, `clk`, `rst_n`, `sel_mux`, `sel_add` | Mẫu phức 32 bit | Gom SR + MUX + Butterfly vào chung. Khối dùng chung cho stage 2–7. Mỗi stage có hai SR cùng độ dài, lần lượt là 32, 16, 8, 4, 2, 1 mẫu. |
| `fft_twiddle_rotate.v` | Mẫu phức 32 bit, địa chỉ ROM `addr`, `rst_n` | Mẫu phức 32 bit | Tra hệ số rồi nhân phức. Stage 2, 4 và 6 lần lượt dùng W128, W32 và W8. |
| `r2_butterfly.v` | Hai mẫu phức A, B, tín hiệu `sel_add` | Kết quả phức | Cộng khi `sel_add=1`, trừ khi `sel_add=0`, rồi dịch phải một bit. |
| `trivial_rotator.v` | Mẫu phức, chế độ xoay `mode` | Mẫu phức đã xoay | Nhân với 1, −j, −1 hoặc +j, có bão hòa khi đổi dấu. |
| `complex_mult.v` | Mẫu phức Q8.8, hệ số phức Q1.15 | Mẫu phức Q8.8 | Nhân phức và bão hòa từng thành phần về 16 bit. |
| `twiddle_rom_128.v` | `addr` 7 bit, `in_valid`, `rst_n` | `tw_re`, `tw_im` Q1.15, `out_valid` | Tra 128 hệ số W128. |
| `mux2to1_16bit.v` | Hai dữ liệu 16 bit, `sel` | Dữ liệu được chọn | Chọn `in0` khi `sel=0`, ngược lại chọn `in1`. |
| `shift_register.v` | `clk`, `rst_n`, dữ liệu `DATA_W` bit | Dữ liệu trễ 1 chu kỳ | Lưu một mẫu tại cạnh lên của clock. |
| `SR_L.v` | `clk`, `rst_n`, dữ liệu `DATA_W` bit | Dữ liệu trễ `LENGTH` chu kỳ | Nối nhiều thanh ghi để tạo đường trễ. |
| `FFT_128.qpf`, `FFT_128.qsf` | — | — | File mở project và file cấu hình nguồn, FPGA, top level trong Quartus. |
