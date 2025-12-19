import inputMethodEngine from '@ohos.inputMethodEngine';
import type InputMethodExtensionContext from '@ohos.InputMethodExtensionContext';
import display from '@ohos.display';

import { TelexEngine, TelexActionKind } from './TelexEngine';

const UI_PAGE: string = 'InputMethodExtensionAbility/pages/Index';

// ---- Height tuning (vp) ----
const KEYBOARD_CONTENT_HEIGHT_VP: number = 228;
const KEYBOARD_SAFE_BOTTOM_VP: number = 12;
const KEYBOARD_TOTAL_HEIGHT_VP: number = KEYBOARD_CONTENT_HEIGHT_VP + KEYBOARD_SAFE_BOTTOM_VP;

class PanelSize {
  widthPx: number = 0;
  heightPx: number = 0;
}

class PanelInfoImpl implements inputMethodEngine.PanelInfo {
  type: inputMethodEngine.PanelType = inputMethodEngine.PanelType.SOFT_KEYBOARD;
  flag: inputMethodEngine.PanelFlag = inputMethodEngine.PanelFlag.FLG_FIXED;
}

function getPanelSizePx(): PanelSize {
  const s: PanelSize = new PanelSize();
  try {
    const d: display.Display = display.getDefaultDisplaySync();
    const vpr: number = d.densityPixels > 0 ? d.densityPixels : 1;
    s.widthPx = d.width;
    s.heightPx = Math.max(1, Math.round(KEYBOARD_TOTAL_HEIGHT_VP * vpr));
    return s;
  } catch {
    s.widthPx = 1080;
    s.heightPx = 720;
    return s;
  }
}

export class KeyboardController {
  private panel?: inputMethodEngine.Panel;
  private textInputClient?: inputMethodEngine.TextInputClient;
  private pendingShow: boolean = false;

  // ===== Telex composing (OpenKey-like) =====
  private composingWord: string = '';
  // modernOrthography=true (oà/uý), quickTelex=false (tuỳ bạn bật sau)
  private readonly telex: TelexEngine = new TelexEngine(true, false);

  // ===== Backspace hold-to-repeat =====
  private backspaceHolding: boolean = false;
  private backspaceDelayTimerId: number = 0;
  private backspaceRepeatTimerId: number = 0;

  private readonly backspaceInitialDelayMs: number = 350;
  private readonly backspaceRepeatIntervalMs: number = 55;

  private setTimeoutId(handler: () => void, delayMs: number): number {
    return setTimeout(handler, delayMs) as number;
  }

  private setIntervalId(handler: () => void, intervalMs: number): number {
    return setInterval(handler, intervalMs) as number;
  }

  onCreate(context: InputMethodExtensionContext): void {
    const ime: inputMethodEngine.InputMethodAbility = inputMethodEngine.getInputMethodAbility();
    if (!ime) return;

    this.initPanel(context, ime);

    ime.on('inputStart',
      (_kbCtrl: inputMethodEngine.KeyboardController, client: inputMethodEngine.TextInputClient) => {
        this.textInputClient = client;
        this.resetComposing();

        if (this.panel) {
          this.panel.show();
        } else {
          this.pendingShow = true;
        }
      });

    ime.on('inputStop', () => {
      this.stopBackspaceRepeat();
      this.resetComposing();
      this.textInputClient = undefined;
      this.pendingShow = false;
      this.panel?.hide();
    });
  }

  onDestroy(): void {
    this.stopBackspaceRepeat();
    this.resetComposing();
    this.pendingShow = false;
    try {
      this.panel?.hide();
    } catch {
      // ignore
    }
    this.panel = undefined;
    this.textInputClient = undefined;
  }

  private resetComposing(): void {
    this.composingWord = '';
  }

  private async initPanel(
    context: InputMethodExtensionContext,
    ime: inputMethodEngine.InputMethodAbility
  ): Promise<void> {
    const panelInfo: PanelInfoImpl = new PanelInfoImpl();
    try {
      const panel: inputMethodEngine.Panel = await ime.createPanel(context, panelInfo);

      const size: PanelSize = getPanelSizePx();
      await panel.resize(size.widthPx, size.heightPx);

      panel.setUiContent(UI_PAGE, null);
      this.panel = panel;

      if (this.pendingShow) {
        this.pendingShow = false;
        panel.show();
      }
    } catch {
      // ignore
    }
  }

  private async replaceComposing(newWord: string): Promise<void> {
    const client: inputMethodEngine.TextInputClient | undefined = this.textInputClient;
    if (!client) return;

    const oldLen: number = this.composingWord.length;
    try {
      if (oldLen > 0) {
        await client.deleteForward(oldLen);
      }
      if (newWord.length > 0) {
        await client.insertText(newWord);
      }
      this.composingWord = newWord;
    } catch {
      // ignore
    }
  }

  private async appendText(text: string): Promise<void> {
    const client: inputMethodEngine.TextInputClient | undefined = this.textInputClient;
    if (!client) return;

    try {
      await client.insertText(text);
    } catch {
      // ignore
    }
  }

  /**
   * Commit text with Telex processing (OpenKey-like).
   * - letters a-z: apply Telex (tone/shape) inside current composing word
   * - space / newline: commit and reset composing
   */
  async commitText(text: string): Promise<void> {
    const client: inputMethodEngine.TextInputClient | undefined = this.textInputClient;
    if (!client) return;

    if (text === ' ' || text === '\n') {
      // Word boundary
      this.resetComposing();
      await this.appendText(text);
      return;
    }

    if (text.length !== 1) {
      // Safety: any multi-char insert resets composing
      this.resetComposing();
      await this.appendText(text);
      return;
    }

    const r = this.telex.apply(this.composingWord, text);

    if (r.kind === TelexActionKind.Replace) {
      await this.replaceComposing(r.newWord);
      return;
    }

    // Append literal key
    await this.appendText(text);
    this.composingWord = this.composingWord + text;
  }

  /**
   * Hold Backspace to repeat.
   * UI gọi startBackspaceRepeat() ở TouchType.Down,
   * stopBackspaceRepeat() ở TouchType.Up/Cancel.
   */
  startBackspaceRepeat(): void {
    if (!this.textInputClient) return;
    if (this.backspaceHolding) return;

    this.backspaceHolding = true;
    this.clearBackspaceTimers();

    // delete 1 immediately
    this.backspace();

    this.backspaceDelayTimerId = this.setTimeoutId(() => {
      if (!this.backspaceHolding) return;

      this.backspaceRepeatTimerId = this.setIntervalId(() => {
        if (!this.backspaceHolding) return;
        this.backspace();
      }, this.backspaceRepeatIntervalMs);

    }, this.backspaceInitialDelayMs);
  }

  stopBackspaceRepeat(): void {
    this.backspaceHolding = false;
    this.clearBackspaceTimers();
  }

  private clearBackspaceTimers(): void {
    if (this.backspaceDelayTimerId !== 0) {
      try { clearTimeout(this.backspaceDelayTimerId); } catch { /* ignore */ }
      this.backspaceDelayTimerId = 0;
    }
    if (this.backspaceRepeatTimerId !== 0) {
      try { clearInterval(this.backspaceRepeatTimerId); } catch { /* ignore */ }
      this.backspaceRepeatTimerId = 0;
    }
  }

  async backspace(): Promise<void> {
    const client: inputMethodEngine.TextInputClient | undefined = this.textInputClient;
    if (!client) return;

    // keep composingWord in sync (best-effort)
    if (this.composingWord.length > 0) {
      this.composingWord = this.composingWord.slice(0, this.composingWord.length - 1);
    }

    // Backspace = deleteForward (xóa ký tự trước con trỏ)
    try {
      await client.deleteForward(1);
    } catch {
      // ignore
    }
  }

  async enter(): Promise<void> {
    await this.commitText('\n');
  }

  async space(): Promise<void> {
    await this.commitText(' ');
  }
}
