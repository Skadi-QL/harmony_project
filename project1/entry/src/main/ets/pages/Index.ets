import { promptAction } from '@kit.ArkUI';
// 游戏方向枚举
enum Direction {
  UP,
  DOWN,
  LEFT,
  RIGHT
}

// 游戏状态
class GameState {
  // 游戏板（4x4）
  board: number[][] = (() => {
    const arr: number[][] = [];
    for (let i = 0; i < 4; i++) {
      arr[i] = [0, 0, 0, 0];
    }
    return arr;
  })();
  // 分数
  score: number = 0;
  // 游戏是否结束
  gameOver: boolean = false;
  // 游戏是否胜利
  win: boolean = false;

  constructor() {
    this.initGame();
  }

  // 初始化游戏
  initGame() {
    // 清空棋盘
    for (let i = 0; i < 4; i++) {
      for (let j = 0; j < 4; j++) {
        this.board[i][j] = 0;
      }
    }
    this.score = 0;
    this.gameOver = false;
    this.win = false;

    // 生成两个初始数字
    this.generateNewNumber();
    this.generateNewNumber();
  }

  // 生成新的数字（90%概率为2，10%概率为4）
  generateNewNumber(): boolean {
    const emptyCells: [number, number][] = [];

    // 查找所有空格子
    for (let i = 0; i < 4; i++) {
      for (let j = 0; j < 4; j++) {
        if (this.board[i][j] === 0) {
          emptyCells.push([i, j]);
        }
      }
    }

    if (emptyCells.length === 0) {
      return false;
    }

    // 随机选择一个空格子
    const randomIndex = Math.floor(Math.random() * emptyCells.length);
    const cell = emptyCells[randomIndex];
    const row = cell[0];  // 明确提取row
    const col = cell[1];  // 明确提取col
    this.board[row][col] = Math.random() < 0.9 ? 2 : 4;

    return true;
  }

  // 检查游戏是否结束
  checkGameOver(): boolean {
    // 检查是否有空格子
    for (let i = 0; i < 4; i++) {
      for (let j = 0; j < 4; j++) {
        if (this.board[i][j] === 0) {
          return false;
        }
      }
    }

    // 检查是否可以合并
    for (let i = 0; i < 4; i++) {
      for (let j = 0; j < 4; j++) {
        const current = this.board[i][j];

        // 检查右侧
        if (j < 3 && current === this.board[i][j + 1]) {
          return false;
        }

        // 检查下方
        if (i < 3 && current === this.board[i + 1][j]) {
          return false;
        }
      }
    }

    return true;
  }

  // 检查是否胜利（达到2048）
  checkWin(): boolean {
    for (let i = 0; i < 4; i++) {
      for (let j = 0; j < 4; j++) {
        if (this.board[i][j] === 2048) {
          return true;
        }
      }
    }
    return false;
  }

  // 移动数字
  move(direction: Direction): boolean {
    const oldBoard = JSON.parse(JSON.stringify(this.board)) as number[][];
    let moved = false;

    switch (direction) {
      case Direction.LEFT:
        moved = this.moveLeft();
        break;
      case Direction.RIGHT:
        moved = this.moveRight();
        break;
      case Direction.UP:
        moved = this.moveUp();
        break;
      case Direction.DOWN:
        moved = this.moveDown();
        break;
    }

    // 如果有移动，生成新数字
    if (moved) {
      this.generateNewNumber();

      // 检查游戏状态
      this.win = this.checkWin();
      this.gameOver = this.checkGameOver();

      if (this.win) {
        try {
          promptAction.showToast({
            message: '恭喜！您达到了2048！',
            duration: 2000  // 明确指定持续时间
          });
        } catch (error) {
          console.error(`Toast显示失败：${error.code}, ${error.message}`);
          // 可选：通过其他方式提示用户（如更新状态变量触发界面文字提示）
        }
      }

      if (this.gameOver && !this.win) {
        try {
          promptAction.showToast({
            message: '游戏结束！',
            duration: 2000  // 明确指定合理持续时间
          });
        } catch (error) {
          console.error(`游戏结束提示异常：code=${error.code}, message=${error.message}`);
        }
      }
    }

    return moved;
  }
  // 向左移动
  private moveLeft(): boolean {
    let moved = false;

    for (let i = 0; i < 4; i++) {
      // 压缩行（移除空格）
      const row = this.board[i].filter(cell => cell !== 0);

      // 合并相同数字
      for (let j = 0; j < row.length - 1; j++) {
        if (row[j] === row[j + 1]) {
          row[j] *= 2;
          this.score += row[j];
          row.splice(j + 1, 1);
        }
      }

      // 填充0
      while (row.length < 4) {
        row.push(0);
      }

      // 检查是否有变化
      if (!this.arraysEqual(this.board[i], row)) {
        moved = true;
        this.board[i] = row;
      }
    }

    return moved;
  }

  // 向右移动
  private moveRight(): boolean {
    let moved = false;

    for (let i = 0; i < 4; i++) {
      // 压缩行（移除空格）
      const row = this.board[i].filter(cell => cell !== 0);

      // 合并相同数字
      for (let j = row.length - 1; j > 0; j--) {
        if (row[j] === row[j - 1]) {
          row[j] *= 2;
          this.score += row[j];
          row.splice(j - 1, 1);
        }
      }

      // 填充0到前面
      while (row.length < 4) {
        row.unshift(0);
      }

      // 检查是否有变化
      if (!this.arraysEqual(this.board[i], row)) {
        moved = true;
        this.board[i] = row;
      }
    }

    return moved;
  }

  // 向上移动
  private moveUp(): boolean {
    let moved = false;

    for (let j = 0; j < 4; j++) {
      // 获取列
      const column: number[] = [];
      for (let i = 0; i < 4; i++) {
        column.push(this.board[i][j]);
      }

      // 压缩列（移除空格）
      const compressed = column.filter(cell => cell !== 0);

      // 合并相同数字
      for (let i = 0; i < compressed.length - 1; i++) {
        if (compressed[i] === compressed[i + 1]) {
          compressed[i] *= 2;
          this.score += compressed[i];
          compressed.splice(i + 1, 1);
        }
      }

      // 填充0
      while (compressed.length < 4) {
        compressed.push(0);
      }

      // 检查是否有变化并更新列
      for (let i = 0; i < 4; i++) {
        if (this.board[i][j] !== compressed[i]) {
          moved = true;
          this.board[i][j] = compressed[i];
        }
      }
    }

    return moved;
  }

  // 向下移动
  private moveDown(): boolean {
    let moved = false;

    for (let j = 0; j < 4; j++) {
      // 获取列
      const column: number[] = [];
      for (let i = 0; i < 4; i++) {
        column.push(this.board[i][j]);
      }

      // 压缩列（移除空格）
      const compressed = column.filter(cell => cell !== 0);

      // 合并相同数字
      for (let i = compressed.length - 1; i > 0; i--) {
        if (compressed[i] === compressed[i - 1]) {
          compressed[i] *= 2;
          this.score += compressed[i];
          compressed.splice(i - 1, 1);
        }
      }

      // 填充0到前面
      while (compressed.length < 4) {
        compressed.unshift(0);
      }

      // 检查是否有变化并更新列
      for (let i = 0; i < 4; i++) {
        if (this.board[i][j] !== compressed[i]) {
          moved = true;
          this.board[i][j] = compressed[i];
        }
      }
    }

    return moved;
  }

  // 比较两个数组是否相等
  private arraysEqual(a: number[], b: number[]): boolean {
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) {
      if (a[i] !== b[i]) return false;
    }
    return true;
  }
}

@Entry
@Component
struct Game2048 {
  // 游戏状态
  @State gameState: GameState = new GameState();

  // 格子颜色映射
  tileColors: Map<number, Color> = new Map([
    [0, Color.White],
    [2, Color.Yellow],
    [4, Color.Pink],
    [8, Color.Orange],
    [16, Color.Red],
    [32, Color.Green],
    [64, Color.Blue],
    [128, Color.Yellow],  // 替换Purple为Magenta
    [256, Color.Brown],
    [512, Color.Pink],     // 替换Cyan为Teal
    [1024, Color.Gray],
    [2048, Color.Black]
  ]);

  // 格子文字颜色
  tileTextColors: Map<number, Color> = new Map([
    [0, Color.Black],
    [2, Color.Black],
    [4, Color.Black],
    [8, Color.White],
    [16, Color.White],
    [32, Color.White],
    [64, Color.White],
    [128, Color.White],
    [256, Color.White],
    [512, Color.White],
    [1024, Color.White],
    [2048, Color.White]
  ]);

  build() {
    Column({ space: 20 }) {
      // 标题和分数
      Row({ space: 20 }) {
        Text('盲盒2048看下方说明')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.Black)

        Column() {
          Text('分数')
            .fontSize(14)
            .fontColor(Color.Gray)
          Text(this.gameState.score.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Blue)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20 })

      // 游戏网格
      Column({ space: 10 }) {
        ForEach(this.gameState.board, (row: number[], rowIndex: number) => {
          Row({ space: 10 }) {
            ForEach(row, (cell: number, colIndex: number) => {
              this.Tile(cell, rowIndex, colIndex)
            })
          }
        })
      }
      .padding(10)
      .backgroundColor('#BBADA0')
      .borderRadius(10)
      .margin({ left: 20, right: 20 })

      // 控制按钮
      Column({ space: 15 }) {
        // 上方向
        Button('↑')
          .width(80)
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.gameState.move(Direction.UP);
          })

        Row({ space: 20 }) {
          // 左方向
          Button('←')
            .width(80)
            .height(50)
            .fontSize(20)
            .onClick(() => {
              this.gameState.move(Direction.LEFT);
            })

          // 重新开始按钮
          Button('重新开始')
            .width(120)
            .height(50)
            .backgroundColor(Color.Red)
            .fontColor(Color.White)
            .onClick(() => {
              this.gameState.initGame();
            })

          // 右方向
          Button('→')
            .width(80)
            .height(50)
            .fontSize(20)
            .onClick(() => {
              this.gameState.move(Direction.RIGHT);
            })
        }

        // 下方向
        Button('↓')
          .width(80)
          .height(50)
          .fontSize(20)
          .onClick(() => {
            this.gameState.move(Direction.DOWN);
          })
      }
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 20 })

      // 游戏状态提示
      if (this.gameState.win) {
        Text('恭喜！您赢得了游戏！')
          .fontSize(20)
          .fontColor(Color.Green)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
      } else if (this.gameState.gameOver) {
        Text('游戏结束！')
          .fontSize(20)
          .fontColor(Color.Red)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
      }

      // 游戏说明
      Text('游戏说明：')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30 })

      Text('本游戏只有当操作后能直接合成才会更新棋盘显示，但真实状态实时更新。希望这能增加趣味性。')
        .fontSize(14)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.Start)
        .margin({ left: 20, right: 20 })
        .padding({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8EF')
  }

  // 单个格子组件
  @Builder
  Tile(value: number, row: number, col: number) {
    Column() {
      if (value !== 0) {
        Text(value.toString())
          .fontSize(this.getFontSize(value))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tileTextColors.get(value) || Color.Black)
      }
    }
    .width(70)
    .height(70)
    .backgroundColor(this.tileColors.get(value) || Color.White)
    .borderRadius(5)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 根据数字大小获取字体大小
  getFontSize(value: number): number {
    if (value < 100) return 24;
    if (value < 1000) return 20;
    return 16;
  }
}