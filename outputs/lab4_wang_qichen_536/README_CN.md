# EE2026 Lab 4 总结与 GPT-4 完成说明

## 你的个性化参数

附录中 `WANG QICHEN` 的提交名是 `GPT4_WANG QICHEN_536_Archive`，因此这里按 `536` 作为个性化数字：

- 右起第 1 个数字: `6`
- 右起第 2 个数字: `3`

所以：

- Subtask A 使用数字 `6`: `MAX_LED = LD8`，`TIME_COUNT = 1.78 s`
- Subtask B 使用数字 `3`: 按钮顺序为 `BTNC -> BTNL -> BTNU -> BTNR -> BTNC -> BTNL`

## Lab 4 从头到尾总结

本实验主题是 sequential circuits，也就是输出不仅取决于当前输入，还取决于过去输入和内部状态。实验从一个最简单的 `assign LED = CLOCK;` 开始，让你理解 clock 是一个周期翻转的信号；然后用计数器在 clock 的正边沿累加，从 100 MHz 的 Basys3 主时钟得到肉眼可见的慢闪烁信号；最后把计数器、mux、LED 控制、按钮状态机和七段数码管整合成一个结构化设计。

Task 1:

- testbench 中 `#5; CLOCK = ~CLOCK;` 表示每 5 个时间单位翻转一次，所以完整周期是 10 个时间单位。
- `timescale 1ns / 1ps` 下，周期是 10 ns，频率是 `1 / 10 ns = 100 MHz`。
- 如果删除 `CLOCK = 0;`，`CLOCK` 初值会是未知值 `X`，`~X` 仍然是 `X`，仿真波形会一直不确定。

Task 2:

- 如果直接把 100 MHz clock 接 LED，LED 实际上在 100 MHz 闪烁，人的眼睛看不出亮灭变化。
- 你通常只会看到 LED 像是一直亮着，或者亮度稳定。

Task 3:

```verilog
module slow_blinky_module(input CLOCK, output reg SLOW_CLOCK = 1'b0);
    reg [3:0] COUNT = 4'b0000;

    always @(posedge CLOCK) begin
        COUNT <= COUNT + 1;
        SLOW_CLOCK <= (COUNT == 4'b0000) ? ~SLOW_CLOCK : SLOW_CLOCK;
    end
endmodule
```

因为 `COUNT` 是 4 bit，所以每 16 个输入 clock cycle 溢出一次。`SLOW_CLOCK` 每 16 个 cycle 翻转一次，因此完整周期需要 32 个输入 cycle，频率是输入 clock 的 `1/32`。

Task 4:

```verilog
always @(posedge CLOCK) begin
    COUNT <= (COUNT == 4'b1000) ? 4'b0000 : COUNT + 1;
    SLOW_CLOCK <= (COUNT == 4'b0000) ? ~SLOW_CLOCK : SLOW_CLOCK;
end
```

这里 `COUNT` 到 `8` 就被强制回到 `0`，所以 `SLOW_CLOCK` 会更早翻转。注意由于 non-blocking assignment 的行为，`SLOW_CLOCK` 判断的是这个 clock edge 之前的 `COUNT` 值。

Task 5:

- 用 100 MHz 主时钟分别产生 `30 Hz`、`3 Hz`、`1 Hz` 的慢闪烁。
- 用 `SW[2:0]` 或指定开关控制 mux，选择接到 LED 的慢闪烁信号。
- 如果三个开关都 OFF，LED 输出 `0`。

Task 6:

- 先产生一个 1 Hz tick 或 1 Hz clock-enable，让 `COUNT` 每秒增加。
- 再用 `COUNT` 控制 `LEDS`：`00 -> LD0`，`01 -> LD1`，`10 -> LD2`，`11 -> LD3`。
- 重点是理解 structural modelling：顶层 module 只负责实例化并连接子模块。

## 已完成的 GPT-4 行为

源文件: `gpt4_wang_qichen_536.v`

约束文件: `Basys3_gpt4_wang_qichen_536.xdc`

顶层模块名:

```verilog
gpt4_wang_qichen_536
```

实现行为：

- 初始时请确保 `SW0` 到 `SW15` 全部 OFF。
- 七段数码管初始全灭。
- 每 `1.78 s` 多亮一个 LED：`LD0`，`LD1`，一直到 `LD8`。
- `LD8` 亮起时，七段数码管同时开始显示 Subtask B 第一步。
- Subtask A 完成后：
  - `LD8..LD5`、`LD1`、`LD0` 保持亮。
  - `SW2 = 1` 时，`LD2` 以 `0.25 Hz` 闪烁。
  - `SW3 = 1` 时，`LD3` 以 `5 Hz` 闪烁。
  - `SW4 = 1` 时，`LD4` 以 `23 Hz` 闪烁。
  - 若多个 `SW2/SW3/SW4` 同时为 1，优先级为 `SW4 > SW3 > SW2`，符合 truth table 的 don't-care 逻辑。
- Subtask B 按顺序按下：
  - 第 1 步: 显示 `c`，按 `BTNC`
  - 第 2 步: 显示 `l`，按 `BTNL`
  - 第 3 步: 显示 `u`，按 `BTNU`
  - 第 4 步: 显示 `r`，按 `BTNR`
  - 第 5 步: 显示 `c`，按 `BTNC`
  - 第 6 步: 显示 `l`，按 `BTNL`
- 正确完成后进入 unlocked mode，`LD15` 永远亮，七段数码管回到第 1 步显示。

## Vivado 使用步骤

1. 建立或打开 Vivado project，board 选 Basys3 / Artix-7。
2. 添加 `gpt4_wang_qichen_536.v` 到 Design Sources。
3. 添加 `Basys3_gpt4_wang_qichen_536.xdc` 到 Constraints。
4. 右键顶层模块 `gpt4_wang_qichen_536`，选择 `Set as Top`。
5. Run Synthesis。
6. Run Implementation。
7. Generate Bitstream。
8. Program Device。
9. 用秒表检查 `LD0` 到 `LD8` 全亮总时间约为 `9 * 1.78 = 16.02 s`。
10. 按顺序测试 `BTNC -> BTNL -> BTNU -> BTNR -> BTNC -> BTNL`，确认 `LD15` 亮起。

## 提交提醒

- Canvas 截止时间: Saturday 26 September 2026, 6:00 A.M.
- 归档前删除 `.sim` 文件夹，确保 archive 小于 5 MB。
- 提交压缩包命名应为：

```text
GPT4_WANG QICHEN_536_Archive
```

请在上传后重新下载 Canvas 上的压缩包，打开 `.xpr` 并确认 bitstream 可以直接 program device。
