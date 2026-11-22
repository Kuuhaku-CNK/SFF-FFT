# FFT128 SFF radix-2²

Dự án thực hiện FFT 128 điểm cho dữ liệu đầu vào thực, gồm 7 tầng butterfly radix-2 được tổ chức thành ba cặp radix-2² và một tầng radix-2 cuối. Top hiện tại của Quartus là `fft128_avalon`, bọc lõi `fft128` bằng giao tiếp Avalon-MM 32-bit và bộ đệm từng khung 128 mẫu.

- Dữ liệu vào là số có dấu 16-bit Q8.8.
- Dữ liệu phức được đóng gói thành `{real[15:0], imag[15:0]}`; mỗi thành phần là số có dấu Q8.8.
- Hệ số quay tổng quát dùng định dạng Q1.15.
- Mỗi butterfly chia kết quả cho 2 bằng dịch phải số học; hệ số chuẩn hóa toàn bộ FFT là `1/128`.
- Đầu ra giữ thứ tự đảo bit của chỉ số bin 7-bit, bắt đầu `0, 64, 32, 96, ...`.

`FFT_128.qsf` chọn `fft128_avalon.v` làm top. Wrapper này gọi lõi `fft128.v`;

## Các file Verilog dùng để tổng hợp

Có 14 file `.v` trong danh sách nguồn của `FFT_128.qsf`.

| File | Module | Mô tả chức năng |
| --- | --- | --- |
| [fft128_avalon.v](fft128_avalon.v) | `fft128_avalon` | Top giao tiếp Avalon-MM 32-bit. Chứa bộ đệm vào `128 × 16-bit`, bộ đệm ra `128 × 32-bit`, các thanh ghi điều khiển/trạng thái và FSM `IDLE → PRIME → RUN`. Nhận đủ 128 mẫu trước START, cấp một mẫu mỗi chu kỳ cho lõi, sau đó cấp 0 để đẩy hết kết quả ra. Dùng `waitrequest` để điều tiết giao dịch bus. |
| [fft128.v](fft128.v) | `fft128` | Top của lõi FFT, nối controller với datapath. Nhận một mẫu thực mỗi chu kỳ và xuất `y_re`, `y_im`, `out_valid`. Khi dùng trực tiếp lõi, cần đưa mẫu đầu tiên trước cạnh lên đầu tiên sau khi nhả reset và cấp các mẫu liên tục. |
| [fft128_controller.v](fft128_controller.v) | `fft128_controller` | Sinh `sel_mux[6:0]`, `sel_add[6:0]` cho 7 tầng, chế độ quay đơn giản ở tầng 1/3/5, địa chỉ hệ số `k_w128`, `k_w32`, `k_w8` và tín hiệu `out_valid`. Dùng bộ đếm chu kỳ để căn pha theo độ trễ từng tầng. |
| [fft128_datapath.v](fft128_datapath.v) | `fft128_datapath` | Ghép toàn bộ 7 tầng SFF với độ dài mỗi đường trễ lần lượt `64, 32, 16, 8, 4, 2, 1`. Đặt khối quay đơn giản sau tầng 1/3/5 và khối nhân hệ số tổng quát sau tầng 2/4/6. |
| [fft_stage.v](fft_stage.v) | `fft_stage` | Tầng đầu dành cho dữ liệu thực. Gồm hai đường trễ `SR_L` rộng 16-bit, mux chọn dữ liệu, butterfly và `trivial_rotator`. Trong FFT128, tham số `SR_LENGTH = 64`; phần ảo đưa vào butterfly bằng 0. |
| [sff_complex_butterfly.v](sff_complex_butterfly.v) | `sff_complex_butterfly` | Khối SFF dùng chung cho tầng 2 đến tầng 7. Gồm hai đường trễ rộng 32-bit cho dữ liệu phức, hai mux chọn phần thực/ảo và một `r2_butterfly`. Khối quay được ghép riêng bên ngoài khi cần. |
| [r2_butterfly.v](r2_butterfly.v) | `r2_butterfly` | Bộ cộng/trừ phức có tham số `DATA_W`. Với `sel_add = 1`, tính `(A + B) >>> 1`; với `sel_add = 0`, tính `(B - A) >>> 1`. Mở rộng dấu thêm một bit trước phép tính, dùng XOR và carry-in để chọn cộng hoặc trừ. |
| [SR_L.v](SR_L.v) | `SR_L` | Tạo đường trễ dài `LENGTH` chu kỳ bằng cách nối tiếp các `shift_register`. Tham số `DATA_W` xác định độ rộng mỗi mẫu. |
| [shift_register.v](shift_register.v) | `shift_register` | Thanh ghi trễ một chu kỳ, chốt dữ liệu tại cạnh lên của `clk`; reset bất đồng bộ mức thấp đưa đầu ra về 0. Độ rộng dữ liệu được đặt bằng `DATA_W`. |
| [mux2to1_16bit.v](mux2to1_16bit.v) | `mux2to1` | Mux tổ hợp 2 ngõ vào, rộng 16-bit. `sel = 0` chọn `in0`, `sel = 1` chọn `in1`. Tên module là `mux2to1`, khác tên file. |
| [trivial_rotator.v](trivial_rotator.v) | `trivial_rotator` | Quay dữ liệu phức bằng đổi vị trí và đổi dấu các thành phần. `mode = 00/01/10/11` tương ứng nhân với `1/-j/-1/+j`. Khi đổi dấu giá trị âm nhỏ nhất, kết quả được bão hòa về giá trị dương lớn nhất. |
| [fft_twiddle_rotate.v](fft_twiddle_rotate.v) | `fft_twiddle_rotate` | Ghép `twiddle_rom_128` với `complex_mult` để nhân dữ liệu phức với `W128^addr`. Được dùng cho các hệ số W128, W32 và W8 bằng cách ánh xạ địa chỉ về cùng bảng W128. |
| [twiddle_rom_128.v](twiddle_rom_128.v) | `twiddle_rom_128` | Bảng 128 hệ số `exp(-j × 2π × addr / 128)` theo định dạng Q1.15. Mỗi phần tử chứa phần thực và phần ảo 16-bit. Đọc tổ hợp; `out_valid = rst_n & in_valid`, đầu ra hệ số bằng 0 khi không hợp lệ. |
| [complex_mult.v](complex_mult.v) | `complex_mult` | Nhân phức tổ hợp bằng bốn phép nhân thực 16 × 16-bit. Tính phần thực `ac - bd` và phần ảo `ad + bc` bằng trung gian 33-bit; loại 15 bit phân số để đưa kết quả về Q8.8 và bão hòa khi vượt miền signed 16-bit. |
## Cấu trúc kết nối chính

```text
fft128_avalon
├── Thanh ghi Avalon-MM, FSM và bộ đệm vào/ra
└── fft128
    ├── fft128_controller
    └── fft128_datapath
        ├── Tầng 1: fft_stage, L = 64, quay đơn giản
        ├── Tầng 2: sff_complex_butterfly, L = 32, nhân W128
        ├── Tầng 3: sff_complex_butterfly, L = 16, quay đơn giản
        ├── Tầng 4: sff_complex_butterfly, L = 8, nhân W32
        ├── Tầng 5: sff_complex_butterfly, L = 4, quay đơn giản
        ├── Tầng 6: sff_complex_butterfly, L = 2, nhân W8
        └── Tầng 7: sff_complex_butterfly, L = 1
```

`L` là độ dài của mỗi đường trễ; mỗi tầng có hai đường trễ nối tiếp. Các khối quay tổng quát dùng chung loại ROM W128, với địa chỉ lần lượt `k_w128`, `k_w32 << 2` và `k_w8 << 4`.
