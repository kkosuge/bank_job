require 'bank_job/strategy'

module BankJob
  module Strategy
    class Sumishin
      include BankJob::Strategy

      def details
        menu_page
        page  = agent.get('https://www.netbk.co.jp/wpl/NBGate/i020201CT')
        table = page.root.xpath('//*[@class="tableb02"]/table/tbody')
        cols  = table.css('tr')
        [].tap do |details|
          cols.each do |col|
            tds = col.css('td')
            details << Hashie::Mash.new({
              date:    tds[0].text,
              draw:    tds[1].text,
              deposit: tds[2].text,
              subject: tds[3].text,
              balance: tds[4].text,
            })
          end
        end.reverse
      end

      def deposit
        details.last.balance
      end

      def deposits
        deposit
      end

      private

      def menu_page
        @menu_page ||= login
      end

      def login
        page = agent.get('https://www.netbk.co.jp/wpl/NBGate')
        page.form_with(:name => 'LoginForm') do |form|
          form.field_with(:name => 'userName').value = @number
          form.field_with(:name => 'loginPwdSet').value = @pin
          form.submit
        end
        if page.uri.to_s == 'https://www.netbk.co.jp/wpl/NBGate/i010101CT'
          page.form_with(:name => 'form0103_01_100') do |form|
            form.submit
          end
        end
        page
      end
    end
  end
end
