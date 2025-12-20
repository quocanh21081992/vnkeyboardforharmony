// entry/src/main/ets/InputMethodExtensionAbility/pages/Index.ets
import keyboardController from '../model/KeyboardControllerSingleton';
import { KEYBOARD_ROWS, KeyData, KeyKind } from './KeyboardKeyData';

class KbStyle {
  bg: string = '#242424';

  // Tăng nhẹ padding để layout giống bàn phím hệ thống hơn
  padding: number = 2;

  // GIỮ NGUYÊN: thanh pad dưới
  safeBottom: number = 12;

  // Phím + khoảng cách giống bàn phím bên phải hơn
  keyH: number = 44;
  gap: number = 4;
  radius: number = 6;

  keyBg: string = '#2C2C2E';
  keyBgPressed: string = '#3A3A3C';

  keyBgFn: string = '#2A2A2C';
  keyBgFnPressed: string = '#3A3A3C';

  textColor: string = '#EDEDED';
  textSize: number = 18;

  spaceHint: string = '#B9B100';
  spaceHintAlpha: number = 0.55;

  // Preview bar: giữ nhưng không làm nhỏ key nữa
  previewBg: string = '#1F1F1F';
  previewTextColor: string = '#EDEDED';
  previewHintColor: string = '#9A9A9A';
  previewH: number = 24;
  previewRadius: number = 6;
}

@Entry
@Component
struct Index {
  private s: KbStyle = new KbStyle();

  @State private shiftOn: boolean = false;
  @State private pressedKeyId: string = '';

  @State private previewText: string = '';
  private previewTimerId: number = 0;

  private syncPreview(): void {
    const t: string = keyboardController.getPreviewText();
    if (t !== this.previewText) {
      this.previewText = t;
    }
  }

  aboutToAppear(): void {
    this.previewTimerId = setInterval(() => {
      this.syncPreview();
    }, 80) as number;

    this.syncPreview();
  }

  aboutToDisappear(): void {
    if (this.previewTimerId !== 0) {
      try { clearInterval(this.previewTimerId); } catch { /* ignore */ }
      this.previewTimerId = 0;
    }
  }

  private rowIndent(rowIdx: number): number {
    if (rowIdx === 1) return 14;
    if (rowIdx === 2) return 6;
    return 0;
  }

  private isFn(k: KeyData): boolean {
    return k.kind !== KeyKind.Char;
  }

  private labelOf(k: KeyData): string {
    if (k.kind === KeyKind.Char) return this.shiftOn ? k.label.toUpperCase() : k.label;
    if (k.kind === KeyKind.Shift) return '⇧';
    if (k.kind === KeyKind.Backspace) return '⌫';
    if (k.kind === KeyKind.Enter) return '⏎';
    if (k.kind === KeyKind.Space) return '';
    if (k.kind === KeyKind.Num123) return '123';
    return k.label;
  }

  private bgColorOf(k: KeyData): string {
    const pressed: boolean = (this.pressedKeyId === k.id);
    if (this.isFn(k)) {
      return pressed ? this.s.keyBgFnPressed : this.s.keyBgFn;
    }
    return pressed ? this.s.keyBgPressed : this.s.keyBg;
  }

  private onKey(k: KeyData): void {
    if (k.kind === KeyKind.Shift) {
      this.shiftOn = !this.shiftOn;
      return;
    }

    // Placeholder: lần sau làm layout số
    if (k.kind === KeyKind.Num123) {
      // TODO: switch to numeric layout
      return;
    }

    if (k.kind === KeyKind.Space) {
      keyboardController.space();
      this.previewText = '';
      setTimeout(() => this.syncPreview(), 0);
      return;
    }

    if (k.kind === KeyKind.Enter) {
      keyboardController.enter();
      this.previewText = '';
      setTimeout(() => this.syncPreview(), 0);
      return;
    }

    const out: string = this.shiftOn ? k.value.toUpperCase() : k.value;
    keyboardController.commitText(out);

    this.syncPreview();

    if (this.shiftOn) this.shiftOn = false;
  }

  private handleTouch(k: KeyData, e: TouchEvent): void {
    if (e.type === TouchType.Down) {
      this.pressedKeyId = k.id;

      if (k.kind === KeyKind.Backspace) {
        keyboardController.startBackspaceRepeat();
      }
    } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
      this.pressedKeyId = '';

      if (k.kind === KeyKind.Backspace) {
        keyboardController.stopBackspaceRepeat();
        this.syncPreview();
      }
    }
  }

  @Builder
  private KeyView(k: KeyData) {
    Stack() {
      if (k.kind === KeyKind.Space) {
        Row() {
          Blank()
          Stack()
            .height(4)
            .width('55%')
            .borderRadius(999)
            .backgroundColor(this.s.spaceHint)
            .opacity(this.s.spaceHintAlpha);
          Blank()
        }
        .width('100%')
        .height('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center);
      } else {
        Text(this.labelOf(k))
          .fontSize(this.s.textSize)
          .fontColor(this.s.textColor)
          .fontWeight(this.isFn(k) ? FontWeight.Medium : FontWeight.Regular);
      }
    }
    .height(this.s.keyH)
    .margin({ left: this.s.gap / 2, right: this.s.gap / 2 })
    .borderRadius(this.s.radius)
    .backgroundColor(this.bgColorOf(k))
    .onTouch((e: TouchEvent) => {
      this.handleTouch(k, e);
    })
    .onClick(() => {
      if (k.kind !== KeyKind.Backspace) {
        this.onKey(k);
        this.pressedKeyId = '';
      }
    })
    .layoutWeight(k.weight);
  }

  @Builder
  private PreviewBar() {
    Stack() {
      if (this.previewText.length > 0) {
        Text(this.previewText)
          .fontSize(15)
          .fontColor(this.s.previewTextColor)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ left: 10, right: 10 });
      } else {
        Text('Bảng gõ tạm')
          .fontSize(12)
          .fontColor(this.s.previewHintColor)
          .padding({ left: 10, right: 10 });
      }
    }
    .height(this.s.previewH)
    .width('100%')
    .borderRadius(this.s.previewRadius)
    .backgroundColor(this.s.previewBg)
    .margin({ bottom: this.s.gap });
  }

  build() {
    Column() {
      this.PreviewBar();

      ForEach(KEYBOARD_ROWS, (row: Array<KeyData>, rowIdx: number) => {
        Row() {
          ForEach(row, (k: KeyData) => {
            this.KeyView(k);
          }, (k: KeyData) => k.id);
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: this.rowIndent(rowIdx), right: this.rowIndent(rowIdx) })
        // đồng đều khoảng cách hàng, hàng đầu tiên không cần +1 nữa
        .margin({ top: rowIdx === 0 ? 0 : this.s.gap });
      }, (_row: Array<KeyData>, idx: number) => String(idx));
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.s.bg)
    .padding({
      left: this.s.padding,
      right: this.s.padding,
      top: this.s.padding,
      // GIỮ NGUYÊN: pad dưới
      bottom: this.s.padding + this.s.safeBottom
    });
  }
}
