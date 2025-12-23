@Entry
@Component
struct Index {
  private go(url: string) {
    try {
      this.getUIContext().getRouter().pushUrl({ url })
    } catch (e) {
      console.error('pushUrl failed:', JSON.stringify(e))
    }
  }

  @Builder
  private MenuItem(title: string, desc: string, url: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .textAlign(TextAlign.Start)
          .width('100%')

        Text(desc)
          .margin({ top: 4 })
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .lineHeight(18)
          .textAlign(TextAlign.Start)
          .width('100%')
      }
      .layoutWeight(1)

      Text('›')
        .fontSize(22)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%') // ✅ full width card
    .padding(16)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(14)
    .onClick(() => this.go(url))
  }

  build() {
    Column() {
      Text('Vietnam Keyboard')
        .width('100%')
        .textAlign(TextAlign.Start) // ✅ left
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .padding({ top: 18, bottom: 18, left: 16, right: 16 })

      Column({ space: 12 }) {
        this.MenuItem('Chính sách và quyền riêng tư', 'Thông tin thu thập dữ liệu và cách sử dụng', 'pages/Privacy')
        this.MenuItem('Giới thiệu về ứng dụng', 'Tính năng, hướng dẫn và liên hệ', 'pages/About')
        this.MenuItem('Quyền tác giả', 'Thông tin bản quyền và giấy phép', 'pages/Copyright')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Column() {
        Divider()
          .color($r('app.color.divider'))
          .margin({ top: 18, bottom: 10 })

        Text('© 2025 Vietnam Keyboard')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Start) // ✅ left
          .padding({ bottom: 14 })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
