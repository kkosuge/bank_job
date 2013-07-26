require 'bank_job/strategy'

module BankJob
  module Strategy
    class JNB
      include BankJob::Strategy

      def login
        page = agent.get("https://login.japannetbank.co.jp/login_L.html")

        form = page.form_with(name: "HOST")
        form.action    = "https://login.japannetbank.co.jp/cgi-bin/NBPF2101"
        form["TenNo"]  = @number[0..2]
        form["KozaNo"] = @number[3..9]
        form["Pw"]     = @pin

        form["userAgent"] = @agent.user_agent
        form["__uid"] = form["TenNo"] + form["KozaNo"]

        next_page = form.submit
        form = next_page.form_with(name: "HOST")
        form.submit
      end

      def details
        form = welcome_page.form_with(name: "HOST")
        form.action = "https://login.japannetbank.co.jp/cgi-bin/NBPF2101"

        form["CampaignId"] = ""
        form["__type"] = "0023"
        form["__fid"] = "NBG23061"
        form["B_ID"] = "1"
        form["__ngid"] = ""
        form["NextPid"] = ""

        page = form.submit
        page.encoding = 'Shift_JIS'  

        page.root.css(".tableLayoutC01/tr")[1..-1].map do |e|
          tds = e.css("td").map(&:text)

          Hashie::Mash.new({
            date:    Time.parse(tds[0].gsub(/\s/, "").gsub(/[年|月]/, "/").sub("日", " ")),
            draw:    tds[4].strip,
            deposit: tds[5].strip,
            subject: tds[6],
            balance: tds[7].strip,
          })
        end
      end

      def deposit
        details.last.balance
      end

      def deposits
        deposit
      end

      def welcome_page
        @welcome_page ||= login
      end

      def logout
        if @welcome_page
          form = @welcome_page.form_with(name: "HOST")
          form.action = "https://login.japannetbank.co.jp/cgi-bin/NBPF2101"

          form["__type"] = "0002"
          form["__fid"] = "NBPG2201"
          form["B_ID"] = ""
          form["target"] = "_self"
          form["NextPid"] = ""

          form.submit
        end
      end

      private

      def login_number
        @number
      end
    end
  end
end
