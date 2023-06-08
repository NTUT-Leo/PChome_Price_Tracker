import csv
import smtplib
from robot.libraries.BuiltIn import BuiltIn
from robot.api.deco import keyword
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

class extendedKeywords:
    def __getattr__(self, name):
        if name == 'selenium':
            self.selenium = BuiltIn().get_library_instance('SeleniumLibrary')
            return self.selenium
    
    def _current_browser(self):
        return self.selenium.driver
    
    @keyword(name='Scroll To Bottom')
    def scroll_to_bottom(self):
        scrollToBottom = ('var scrollHeight = Math.max(document.body.scrollHeight || document.documentElement.scrollHeight);'
                          'window.scrollTo({'
                          '    top: scrollHeight,'
                          '    behavior: "smooth"'
                          '});')
        self._current_browser().execute_script(scrollToBottom)

    @keyword(name='Scroll Element Into Center Of View')
    def scroll_element_into_center_of_view(self, locator):
        element = self._current_browser().find_element_by_xpath(locator)
        scrollElementIntoMiddle = ('var viewPortHeight = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);'
                                   'var elementTop = arguments[0].getBoundingClientRect().top;'
                                   'window.scrollBy({'
                                   '    top: elementTop-(viewPortHeight/2),'
                                   '    behavior: "smooth"'
                                   '});')
        self._current_browser().execute_script(scrollElementIntoMiddle, element)

    @keyword(name='Create Database')
    def create_database(self, products):
        with open('./database/Price Tracking List.csv', 'w', newline='', errors='ignore') as file:
            writer = csv.DictWriter(file, fieldnames=['商品名稱', '目前價格', '歷史最低價格' ,'連結', '圖片'])
            writer.writeheader()
            for product in products:
                writer.writerow({'商品名稱': product['name'], '目前價格': product['price'], '歷史最低價格': product['price'], '連結': product['link'], '圖片': product['image']})

    @keyword(name='Compare And Update Database')
    def compare_and_update_database(self, products):
        send_list = []
        save_list = []
        with open('./database/Price Tracking List.csv', 'r', newline='') as file:
            reader = csv.DictReader(file)
            dictionaries = list(reader)
            for product in products:
                common_field = {'商品名稱': product['name'], '目前價格': product['price'], '連結': product['link'], '圖片': product['image']}
                data = next((data for data in dictionaries if data['連結'] == product['link']), None)
                if data is not None:
                    if int(product['price']) < int(data['目前價格']):
                        record_low, price = (True, product['price']) if int(product['price']) < int(data['歷史最低價格']) else (False, data['歷史最低價格'])
                        send_list.append({**common_field, '前次價格': data['目前價格'], '歷史最低': record_low})
                        save_list.append({**common_field, '歷史最低價格': price})
                    else:
                        save_list.append({**common_field, '歷史最低價格': data['歷史最低價格']})
                else:
                    save_list.append({**common_field, '歷史最低價格': product['price']})

        with open('./database/Price Tracking List.csv', 'w', newline='', errors='ignore') as file:
            writer = csv.DictWriter(file, fieldnames=['商品名稱', '目前價格', '歷史最低價格' ,'連結', '圖片'])
            writer.writeheader()
            writer.writerows(save_list)
        return send_list
    
    @keyword(name='Send Discount Notification Mail To User')
    def send_discount_notification_mail_to_user(self, products):
        product_block = """
                        <div id="u_row_3" class="u-row-container v-row-padding--vertical" style="padding: 0px 0px 10px;background-color: transparent">
                            <div class="u-row" style="Margin: 0 auto;min-width: 320px;max-width: 500px;overflow-wrap: break-word;word-wrap: break-word;word-break: break-word;background-color: transparent;">
                                <div style="border-collapse: collapse;display: table;width: 100%;height: 100%;background-color: transparent;">
                                    <!--[if (mso)|(IE)]><table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td style="padding: 0px 0px 10px;background-color: transparent;" align="center"><table cellpadding="0" cellspacing="0" border="0" style="width:500px;"><tr style="background-color: transparent;"><![endif]-->

                                    <!--[if (mso)|(IE)]><td align="center" width="250" style="width: 250px;padding: 0px;border-top: 0px solid transparent;border-left: 0px solid transparent;border-right: 0px solid transparent;border-bottom: 0px solid transparent;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;" valign="top"><![endif]-->
                                    <div class="u-col u-col-50" style="max-width: 320px;min-width: 250px;display: table-cell;vertical-align: top;">
                                        <div style="height: 100%;width: 100% !important;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;">
                                            <!--[if (!mso)&(!IE)]><!--><div style="box-sizing: border-box; height: 100%; padding: 0px;border-top: 0px solid transparent;border-left: 0px solid transparent;border-right: 0px solid transparent;border-bottom: 0px solid transparent;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;"><!--<![endif]-->

                                                <table style="font-family:arial,helvetica,sans-serif;" role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                                    <tbody>
                                                        <tr>
                                                            <td class="v-container-padding-padding" style="overflow-wrap:break-word;word-break:break-word;padding:10px;font-family:arial,helvetica,sans-serif;" align="left">
                                                                <table width="100%" cellpadding="0" cellspacing="0" border="0">
                                                                    <tr>
                                                                        <td class="v-text-align" style="padding-right: 0px;padding-left: 0px;" align="center">
                                                                            <img align="center" border="0" src="{圖片}" alt="" title="" style="outline: none;text-decoration: none;-ms-interpolation-mode: bicubic;clear: both;display: inline-block !important;border: none;height: auto;float: none;width: 100%;max-width: 230px;" width="230" /></td></tr></table></td></tr></tbody></table>

                                            <!--[if (!mso)&(!IE)]><!--></div><!--<![endif]-->
                                        </div>
                                    </div>
                                    <!--[if (mso)|(IE)]></td><![endif]-->
                                    <!--[if (mso)|(IE)]><td align="center" width="250" style="width: 250px;padding: 0px;border-top: 0px solid transparent;border-left: 0px solid transparent;border-right: 0px solid transparent;border-bottom: 0px solid transparent;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;" valign="top"><![endif]-->
                                    <div class="u-col u-col-50" style="max-width: 320px;min-width: 250px;display: table-cell;vertical-align: top;">
                                        <div style="height: 100%;width: 100% !important;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;">
                                            <!--[if (!mso)&(!IE)]><!--><div style="box-sizing: border-box; height: 100%; padding: 0px;border-top: 0px solid transparent;border-left: 0px solid transparent;border-right: 0px solid transparent;border-bottom: 0px solid transparent;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;"><!--<![endif]-->

                                                <table style="font-family:arial,helvetica,sans-serif;" role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                                    <tbody>
                                                        <tr>
                                                            <td class="v-container-padding-padding" style="overflow-wrap:break-word;word-break:break-word;padding:10px;font-family:arial,helvetica,sans-serif;" align="left">
                                                                <div class="v-text-align v-line-height" style="font-size: 18px; line-height: 140%; text-align: left; word-wrap: break-word;">
                                                                    <p style="line-height: 140%;">{商品名稱}</p></div></td></tr></tbody></table>

                                                <table style="font-family:arial,helvetica,sans-serif;" role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                                    <tbody>
                                                        <tr>
                                                            <td class="v-container-padding-padding" style="overflow-wrap:break-word;word-break:break-word;padding:10px 10px 10px 15px;font-family:arial,helvetica,sans-serif;" align="left">
                                                                <div class="v-text-align v-line-height" style="font-size: 20px; line-height: 0%; text-align: left; word-wrap: break-word;">
                                                                    <p style="line-height: 0%;"><span style="color: #969696; line-height: 0px;"><em><span style="text-decoration: line-through; line-height: 0px;">${前次價格}</span></em></span></p></div></td></tr></tbody></table>

                                                {歷史最低}
                                                
                                                <table id="u_content_text_4" style="font-family:arial,helvetica,sans-serif;" role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                                    <tbody>
                                                    <tr>
                                                        <td class="v-container-padding-padding" style="overflow-wrap:break-word;word-break:break-word;padding:0px 10px 10px 30px;font-family:arial,helvetica,sans-serif;" align="left">
                                                            <div class="v-text-align v-line-height" style="font-size: 26px; line-height: 140%; text-align: left; word-wrap: break-word;">
                                                                <p style="line-height: 140%;"><span style="color: #ea1717; line-height: 36.4px;"><strong>${目前價格}</strong></span></p></div></td></tr></tbody></table>

                                                <table id="u_content_button_2" style="font-family:arial,helvetica,sans-serif;" role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                                    <tbody>
                                                        <tr>
                                                            <td class="v-container-padding-padding" style="overflow-wrap:break-word;word-break:break-word;padding:0px;font-family:arial,helvetica,sans-serif;" align="left">
                                                                <!--[if mso]><style>.v-button {{background: transparent !important;}}</style><![endif]-->
                                                                <div class="v-text-align" align="center">
                                                                    <!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="{連結}" style="height:37px; v-text-anchor:middle; width:100px;" arcsize="21.5%"  stroke="f" fillcolor="#ea1717"><w:anchorlock/><center style="color:#ffffff;font-family:arial,helvetica,sans-serif;"><![endif]-->
                                                                    <a href="{連結}" target="_blank" class="v-button" style="box-sizing: border-box;display: inline-block;font-family:arial,helvetica,sans-serif;text-decoration: none;-webkit-text-size-adjust: none;text-align: center;color: #ffffff; background-color: #ea1717; border-radius: 8px;-webkit-border-radius: 8px; -moz-border-radius: 8px; width:auto; max-width:100%; overflow-wrap: break-word; word-break: break-word; word-wrap:break-word; mso-border-alt: none;font-family: inherit; font-size: 15px;">
                                                                        <span class="v-line-height v-padding" style="display:block;padding:10px 20px 9px;line-height:120%;"><strong><span style="line-height: 18px;">立即前往</span></strong></span></a>
                                                                    <!--[if mso]></center></v:roundrect><![endif]-->
                                                                </div></td></tr></tbody></table>

                                            <!--[if (!mso)&(!IE)]><!--></div><!--<![endif]-->
                                        </div>
                                    </div>
                                    <!--[if (mso)|(IE)]></td><![endif]-->
                                    <!--[if (mso)|(IE)]></tr></table></td></tr></table><![endif]-->
                                </div>
                            </div>
                        </div>
                        """
        record_low = """
                    <table id="u_content_text_3" style="font-family:arial,helvetica,sans-serif;" role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                        <tbody>
                            <tr>
                                <td class="v-container-padding-padding" style="overflow-wrap:break-word;word-break:break-word;padding:10px 10px 0px 20px;font-family:arial,helvetica,sans-serif;" align="left">
                                    <div class="v-text-align v-line-height" style="font-size: 15px; line-height: 140%; text-align: left; word-wrap: break-word;">
                                        <p style="line-height: 140%;"><span style="line-height: 21px;"><strong>🔻<span style="line-height: 21px; color: #ea1717;">歷史最低</span>🔻</strong></span></p></div></td></tr></tbody></table>
                    """
        split_line = """
                    <div class="u-row-container v-row-padding--vertical" style="padding: 0px;background-color: transparent">
                        <div class="u-row" style="Margin: 0 auto;min-width: 320px;max-width: 500px;overflow-wrap: break-word;word-wrap: break-word;word-break: break-word;background-color: transparent;">
                            <div style="border-collapse: collapse;display: table;width: 100%;height: 100%;background-color: transparent;">
                                <!--[if (mso)|(IE)]><table width="100%" cellpadding="0" cellspacing="0" border="0"><tr><td style="padding: 0px;background-color: transparent;" align="center"><table cellpadding="0" cellspacing="0" border="0" style="width:500px;"><tr style="background-color: transparent;"><![endif]-->

                                <!--[if (mso)|(IE)]><td align="center" width="500" style="width: 500px;padding: 0px;border-top: 0px solid transparent;border-left: 0px solid transparent;border-right: 0px solid transparent;border-bottom: 0px solid transparent;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;" valign="top"><![endif]-->
                                <div class="u-col u-col-100" style="max-width: 320px;min-width: 500px;display: table-cell;vertical-align: top;">
                                    <div style="height: 100%;width: 100% !important;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;">
                                        <!--[if (!mso)&(!IE)]><!--><div style="box-sizing: border-box; height: 100%; padding: 0px;border-top: 0px solid transparent;border-left: 0px solid transparent;border-right: 0px solid transparent;border-bottom: 0px solid transparent;border-radius: 0px;-webkit-border-radius: 0px; -moz-border-radius: 0px;"><!--<![endif]-->

                                            <table style="font-family:arial,helvetica,sans-serif;" role="presentation" cellpadding="0" cellspacing="0" width="100%" border="0">
                                                <tbody>
                                                    <tr>
                                                        <td class="v-container-padding-padding" style="overflow-wrap:break-word;word-break:break-word;padding:10px;font-family:arial,helvetica,sans-serif;" align="left">
                                                            <table height="0px" align="center" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-collapse: collapse;table-layout: fixed;border-spacing: 0;mso-table-lspace: 0pt;mso-table-rspace: 0pt;vertical-align: top;border-top: 2px dotted #BBBBBB;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%">
                                                                <tbody>
                                                                    <tr style="vertical-align: top">
                                                                        <td style="word-break: break-word;border-collapse: collapse !important;vertical-align: top;font-size: 0px;line-height: 0px;mso-line-height-rule: exactly;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%">
                                                                            <span>&#160;</span></td></tr></tbody></table></td></tr></tbody></table>

                                        <!--[if (!mso)&(!IE)]><!--></div><!--<![endif]-->
                                    </div>
                                </div>
                                <!--[if (mso)|(IE)]></td><![endif]-->
                                <!--[if (mso)|(IE)]></tr></table></td></tr></table><![endif]-->
                            </div>
                        </div>
                    </div>
                    """
        
        web_content = ""
        with open('./MailTemplate/index.html', 'r', encoding='utf-8') as file:
            html_content = file.read()

        for product in products:
            web_content += product_block.format(圖片=product['圖片'], 商品名稱=product['商品名稱'], 前次價格=product['前次價格'], 歷史最低=record_low if product['歷史最低'] else "", 目前價格=product['目前價格'], 連結=product['連結'])
            web_content += split_line if product != products[-1] else ""

        html_content = html_content.replace('{web_content}', web_content)

        msg = MIMEMultipart('alternative')
        msg['Subject'] = "降價通知"
        msg['From'] = "t107590031@ntut.org.tw"
        msg['To'] = "leo890224@gmail.com"
        msg.attach(MIMEText(html_content, 'html'))

        try:
            with smtplib.SMTP("smtp.gmail.com", 587) as smtp:
                smtp.starttls()
                smtp.login("t107590031@ntut.org.tw", "gjgwluvafsxfcexi")
                smtp.send_message(msg)
            print("Complete!")
        except Exception as e:
            print("Error message: ", e)