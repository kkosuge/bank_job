require 'bank_job/strategy'

module BankJob
  module Strategy
    class SMBC
      include BankJob::Strategy

      def login
        page                = agent.get("https://direct.smbc.co.jp/aib/aibgsjsw5001.jsp")
        form                = page.form_with(name: 'Login')
        form.action         = form['domainSumitomo']
        form['S_BRANCH_CD'] = @number[0..2]
        form['S_ACCNT_NO']  = @number[3..9]
        form['PASSWORD']    = @pin
        page                = form.submit
        raise "Login failed" unless page.uri.to_s == 'https://direct3.smbc.co.jp/servlet/com.smbc.SUPRedirectServlet'
        page
      end

      def accounts
        page = login
        [].tap do |accounts|
          page.root.css('.dataTable td .detailsBtn a').each do |account|
            accounts << Hashie::Mash.new({
              url:    account[:href],
              number: account.text.scan(/\d+\Z/).first,
              text:   account.text
            })
          end
        end
      end

      def details(url = nil)
        url = accounts.first.url unless url
        page  = agent.get(url)
        table = page.root.xpath('//*[@id="note"]/div[1]/div[2]/table[2]')
        cols  = table.css('tr')[1..-2]
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
        end
      end

      def deposit(url = nil)
        if url
          details(url).last.balance
        else
          deposit(accounts.first.url)
        end
      end

      def deposits
        accounts.map do |account|
          deposit(account.url).gsub(',','').to_i
        end.inject(0) { |sum, i| sum + i }.humanize
      end

      private

      def login_number
        @number
      end
    end
  end
end
