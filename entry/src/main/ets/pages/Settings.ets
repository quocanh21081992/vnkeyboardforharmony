// entry/src/main/ets/pages/Settings.ets
import type { common } from '@kit.AbilityKit'
import type { BusinessError } from '@kit.BasicServicesKit'
import { commonEventManager } from '@kit.BasicServicesKit'

import {
  readKeyboardHeightVp,
  writeKeyboardHeightVp,
  bumpKeyboardReloadSeq,
  readInputMethod,
  writeInputMethod,
  readNumberRowEnabled,
  writeNumberRowEnabled,

  readHapticEnabled,
  writeHapticEnabled,
  readHapticIntensity,
  writeHapticIntensity,

  clampHapticIntensity,
  type InputMethodType,

  DEFAULT_KEYBOARD_HEIGHT_VP,
  MIN_KEYBOARD_HEIGHT_VP,
  MAX_KEYBOARD_HEIGHT_VP,
  DEFAULT_NUMBER_ROW_ENABLED,

  DEFAULT_HAPTIC_ENABLED,
  DEFAULT_HAPTIC_INTENSITY,
  MIN_HAPTIC_INTENSITY,
  MAX_HAPTIC_INTENSITY
} from './SettingsStore'

const EVENT_REBUILD_KEYBOARD: string = 'com.quoca.vntelexkeyboard.REBUILD';

@Entry
@Component
struct Settings {
  @State private heightText: string = ''
  @State private inputMethod: InputMethodType = 'telex'
  @State private numberRowEnabled: boolean = DEFAULT_NUMBER_ROW_ENABLED

  @State private hapticEnabled: boolean = DEFAULT_HAPTIC_ENABLED
  @State private hapticIntensity: number = DEFAULT_HAPTIC_INTENSITY

  @State private loading: boolean = true
  @State private saving: boolean = false
  @State private errorText: string = ''

  private methodLabel(m: InputMethodType): string {
    return m === 'vni' ? 'VNI' : 'Telex'
  }

  private back(): void {
    try {
      this.getUIContext().getRouter().back()
    } catch (e) {
      console.error('router back failed: ' + JSON.stringify(e))
    }
  }

  aboutToAppear(): void {
    this.load()
  }

  private load(): void {
    this.loading = true
    this.errorText = ''
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext

      const tasks: Array<Promise<number | InputMethodType | boolean>> = [
        readKeyboardHeightVp(ctx).catch((): number => DEFAULT_KEYBOARD_HEIGHT_VP),
        readInputMethod(ctx).catch((): InputMethodType => 'telex' as InputMethodType),
        readNumberRowEnabled(ctx).catch((): boolean => DEFAULT_NUMBER_ROW_ENABLED),
        readHapticEnabled(ctx).catch((): boolean => DEFAULT_HAPTIC_ENABLED),
        readHapticIntensity(ctx).catch((): number => DEFAULT_HAPTIC_INTENSITY)
      ]

      Promise.all(tasks).then((vals: Array<number | InputMethodType | boolean>): void => {
        const h: number = vals[0] as number
        const m: InputMethodType = vals[1] as InputMethodType
        const nrow: boolean = vals[2] as boolean
        const hOn: boolean = vals[3] as boolean
        const hInt: number = vals[4] as number

        this.heightText = String(h)
        this.inputMethod = m
        this.numberRowEnabled = !!nrow
        this.hapticEnabled = !!hOn
        this.hapticIntensity = clampHapticIntensity(hInt)

        this.loading = false
      }).catch((_e: BusinessError): void => {
        this.heightText = String(DEFAULT_KEYBOARD_HEIGHT_VP)
        this.inputMethod = 'telex'
        this.numberRowEnabled = DEFAULT_NUMBER_ROW_ENABLED
        this.hapticEnabled = DEFAULT_HAPTIC_ENABLED
        this.hapticIntensity = DEFAULT_HAPTIC_INTENSITY
        this.loading = false
      })
    } catch (_e) {
      this.heightText = String(DEFAULT_KEYBOARD_HEIGHT_VP)
      this.inputMethod = 'telex'
      this.numberRowEnabled = DEFAULT_NUMBER_ROW_ENABLED
      this.hapticEnabled = DEFAULT_HAPTIC_ENABLED
      this.hapticIntensity = DEFAULT_HAPTIC_INTENSITY
      this.loading = false
    }
  }

  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message })
    } catch {
      // ignore
    }
  }

  private parseHeight(): number | undefined {
    const raw: string = this.heightText.trim()
    if (raw.length === 0) return undefined
    const n: number = Number(raw)
    if (!Number.isFinite(n)) return undefined
    return Math.round(n)
  }

  private getHeightForRebuild(): number {
    const n: number | undefined = this.parseHeight()
    if (n === undefined || !Number.isFinite(n)) return DEFAULT_KEYBOARD_HEIGHT_VP
    if (n < MIN_KEYBOARD_HEIGHT_VP) return MIN_KEYBOARD_HEIGHT_VP
    if (n > MAX_KEYBOARD_HEIGHT_VP) return MAX_KEYBOARD_HEIGHT_VP
    return n
  }

  private publishRebuild(heightVp: number, method: InputMethodType, numberRowEnabled: boolean, hapticEnabled: boolean, hapticIntensity: number): void {
    try {
      const payload: string = JSON.stringify({
        heightVp: heightVp,
        inputMethod: method,
        numberRowEnabled: !!numberRowEnabled,
        hapticEnabled: !!hapticEnabled,
        hapticIntensity: clampHapticIntensity(hapticIntensity)
      })
      commonEventManager.publish(EVENT_REBUILD_KEYBOARD, { data: payload }, (_err?: BusinessError): void => {
        // ignore
      })
    } catch {
      // ignore
    }
  }

  private onPickInputMethod(m: InputMethodType): void {
    this.inputMethod = m
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      writeInputMethod(ctx, m).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
      bumpKeyboardReloadSeq(ctx).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
    } catch {
      // ignore
    }
    const hVp: number = this.getHeightForRebuild()
    this.publishRebuild(hVp, m, this.numberRowEnabled, this.hapticEnabled, this.hapticIntensity)
  }

  private onToggleNumberRow(next: boolean): void {
    this.numberRowEnabled = !!next
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      writeNumberRowEnabled(ctx, this.numberRowEnabled).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
      bumpKeyboardReloadSeq(ctx).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
    } catch {
      // ignore
    }
    const hVp: number = this.getHeightForRebuild()
    this.publishRebuild(hVp, this.inputMethod, this.numberRowEnabled, this.hapticEnabled, this.hapticIntensity)
  }

  private onToggleHaptics(next: boolean): void {
    this.hapticEnabled = !!next
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      writeHapticEnabled(ctx, this.hapticEnabled).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
    } catch {
      // ignore
    }
    const hVp: number = this.getHeightForRebuild()
    this.publishRebuild(hVp, this.inputMethod, this.numberRowEnabled, this.hapticEnabled, this.hapticIntensity)
  }

  private onChangeHapticIntensity(v: number): void {
    const next: number = clampHapticIntensity(v)
    this.hapticIntensity = next
    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      writeHapticIntensity(ctx, next).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
    } catch {
      // ignore
    }
    const hVp: number = this.getHeightForRebuild()
    this.publishRebuild(hVp, this.inputMethod, this.numberRowEnabled, this.hapticEnabled, this.hapticIntensity)
  }

  @Builder
  private InputMethodMenu() {
    Menu() {
      MenuItem({ content: 'Telex' })
        .onClick((): void => this.onPickInputMethod('telex'))
      MenuItem({ content: 'VNI' })
        .onClick((): void => this.onPickInputMethod('vni'))
    }
  }

  private save(): void {
    if (this.saving || this.loading) return

    const n: number | undefined = this.parseHeight()
    if (n === undefined) {
      this.errorText = 'Vui lòng nhập số hợp lệ.'
      return
    }

    if (n < MIN_KEYBOARD_HEIGHT_VP || n > MAX_KEYBOARD_HEIGHT_VP) {
      this.errorText = `Độ cao phải trong khoảng ${MIN_KEYBOARD_HEIGHT_VP}–${MAX_KEYBOARD_HEIGHT_VP} vp.`
      return
    }

    this.errorText = ''
    this.saving = true

    try {
      const ctx: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      writeKeyboardHeightVp(ctx, n).then((): void => {
        try {
          bumpKeyboardReloadSeq(ctx).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
        } catch { /* ignore */ }

        try {
          writeInputMethod(ctx, this.inputMethod).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
        } catch { /* ignore */ }

        try {
          writeNumberRowEnabled(ctx, this.numberRowEnabled).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
        } catch { /* ignore */ }

        try {
          writeHapticEnabled(ctx, this.hapticEnabled).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
          writeHapticIntensity(ctx, this.hapticIntensity).then((): void => { /* ignore */ }).catch((): void => { /* ignore */ })
        } catch { /* ignore */ }

        this.publishRebuild(n, this.inputMethod, this.numberRowEnabled, this.hapticEnabled, this.hapticIntensity)

        this.saving = false
        this.showToast('Đã lưu cài đặt.')
      }).catch((_e: BusinessError): void => {
        this.saving = false
        this.showToast('Lưu thất bại. Vui lòng thử lại.')
      })
    } catch {
      this.saving = false
      this.showToast('Lưu thất bại. Vui lòng thử lại.')
    }
  }

  private resetToDefault(): void {
    this.heightText = String(DEFAULT_KEYBOARD_HEIGHT_VP)
    this.errorText = ''
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor($r('app.color.text_primary'))
          .padding({ left: 16, right: 10, top: 12, bottom: 12 })
          .onClick((): void => this.back())

        Text($r('app.string.settings_header'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .textAlign(TextAlign.Start)
          .layoutWeight(1)

        Blank().width(46)
      }
      .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          // Card
          Column() {
            // Input method
            Text('Kiểu gõ')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .textAlign(TextAlign.Start)

            Row() {
              Button(this.methodLabel(this.inputMethod))
                .layoutWeight(1)
                .height(44)
                .borderRadius(10)
                .backgroundColor($r('app.color.page_bg'))
                .bindMenu(this.InputMethodMenu)
            }
            .width('100%')
            .margin({ top: 12 })

            // Number row toggle
            Row() {
              Text('Hàng phím số')
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Start)

              Text(this.numberRowEnabled ? 'Bật' : 'Tắt')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .margin({ top: 10 })
            .borderRadius(10)
            .backgroundColor($r('app.color.page_bg'))
            .onClick((): void => this.onToggleNumberRow(!this.numberRowEnabled))

            // Haptics toggle
            Row() {
              Text($r('app.string.settings_haptics_title'))
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Start)

              Text(this.hapticEnabled ? $r('app.string.settings_on') : $r('app.string.settings_off'))
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .margin({ top: 10 })
            .borderRadius(10)
            .backgroundColor($r('app.color.page_bg'))
            .onClick((): void => this.onToggleHaptics(!this.hapticEnabled))

            // Haptics intensity
            Column() {
              Row() {
                Text($r('app.string.settings_haptics_intensity'))
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.Start)

                Text(`${this.hapticIntensity}`)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .margin({ bottom: 6 })

              Slider({ value: this.hapticIntensity, min: MIN_HAPTIC_INTENSITY, max: MAX_HAPTIC_INTENSITY, step: 1 })
                .enabled(this.hapticEnabled)
                .onChange((value: number): void => {
                  this.onChangeHapticIntensity(value)
                })
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .margin({ top: 10 })
            .borderRadius(10)
            .backgroundColor($r('app.color.page_bg'))

            Divider().margin({ top: 16, bottom: 16 })

            Text($r('app.string.settings_keyboard_height_title'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .textAlign(TextAlign.Start)

            Text($r('app.string.settings_keyboard_height_desc'))
              .margin({ top: 8 })
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .lineHeight(18)
              .width('100%')
              .textAlign(TextAlign.Start)

            Row() {
              TextInput({ text: this.heightText, placeholder: String(DEFAULT_KEYBOARD_HEIGHT_VP) })
                .type(InputType.Number)
                .onChange((v: string): void => {
                  this.heightText = v
                  this.errorText = ''
                })
                .layoutWeight(1)
                .height(44)
                .padding({ left: 12, right: 12 })
                .borderRadius(10)
                .backgroundColor($r('app.color.page_bg'))

              Text('vp')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ left: 10 })
            }
            .width('100%')
            .margin({ top: 12 })

            if (this.errorText.length > 0) {
              Text(this.errorText)
                .margin({ top: 10 })
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .textAlign(TextAlign.Start)
            }

            Row({ space: 10 }) {
              Button($r('app.string.settings_reset'))
                .layoutWeight(1)
                .onClick((): void => this.resetToDefault())

              Button(this.saving ? $r('app.string.settings_saving') : $r('app.string.settings_save'))
                .layoutWeight(1)
                .enabled(!this.loading && !this.saving)
                .onClick((): void => this.save())
            }
            .width('100%')
            .margin({ top: 14 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)

          Column() {
            Text($r('app.string.settings_note_title'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .textAlign(TextAlign.Start)

            Text($r('app.string.settings_note_body'))
              .margin({ top: 8 })
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .lineHeight(18)
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)

          Blank().height(18)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
