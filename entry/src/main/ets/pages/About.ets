@Entry
@Component
struct About {
  private back() {
    try {
      this.getUIContext().getRouter().back()
    } catch (e) {
      console.error('router back failed:', JSON.stringify(e))
    }
  }

  @Builder
  private Section(title: string, body: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Start)
        .width('100%')

      Text(body)
        .margin({ top: 8 })
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(18)
        .textAlign(TextAlign.Start)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor($r('app.color.text_primary'))
          .padding({ left: 16, right: 10, top: 12, bottom: 12 })
          .onClick(() => this.back())

        Text('Giới thiệu')
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
          this.Section(
            'Vietnam Keyboard',
            'Vietnam Keyboard là ứng dụng bàn phím tiếng Việt tập trung vào trải nghiệm gõ nhanh, chính xác và giao diện tối giản.'
          )

          this.Section(
            'Tính năng chính (mẫu)',
            '- Gõ tiếng Việt Telex (tuỳ cấu hình).\n' +
              '- Chuyển layout chữ / số / ký tự.\n' +
              '- Tự thích ứng Light/Dark theo hệ thống.'
          )

          this.Section(
            'Hướng dẫn nhanh (mẫu)',
            '1) Bật bàn phím trong Cài đặt hệ thống.\n' +
              '2) Chọn Vietnam Keyboard làm phương thức nhập.\n' +
              '3) Bắt đầu gõ trong bất kỳ ứng dụng nào.'
          )

          this.Section(
            'Liên hệ (mẫu)',
            'Email: support@yourdomain.com\nPhiên bản: 1.0.0'
          )

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
