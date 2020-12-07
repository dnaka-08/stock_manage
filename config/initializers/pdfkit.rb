PDFKit.configure do |config|
  config.wkhtmltopdf = `which wkhtmltopdf`.to_s.strip
  config.default_options = {
    encoding:                "UTF-8",  # エンコーディング
    page_size:               "A3",     # ページのサイズ
    margin_top:              "0.25in", # 余白の設定
    margin_right:            "0.5in",
    margin_bottom:           "0.25in",
    margin_left:             "0.5in",
    orientation:             "Landscape",
    lowquality:              true,  
    disable_smart_shrinking: true
  }
end