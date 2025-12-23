@Entry
@Component
struct Copyright {
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

        Text('Quyền tác giả')
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
            'Bản quyền',
            '© 2025 Vietnam Keyboard. Tất cả quyền được bảo lưu.\n' +
              'Bạn có thể thay bằng tên cá nhân/công ty của bạn.'
          )

          this.Section(
            'Giấy phép (mẫu)',
            '- Nếu dùng thư viện nguồn mở, liệt kê tại đây.\n' +
              '- Nêu rõ giấy phép (MIT/Apache-2.0/...).\n' +
              '- Đính kèm file LICENSE trong dự án (nếu có).'
          )

          this.Section(
            'Ghi chú pháp lý (mẫu)',
            'Ứng dụng không liên kết với bất kỳ thương hiệu bàn phím nào khác. Mọi nhãn hiệu (nếu có) thuộc về chủ sở hữu tương ứng.'
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
