require 'bank_job/strategy'

module BankJob
  module Strategy
    class Mizuho
      include BankJob::Strategy

      LOGIN_PARAM = "?xtr=Emf00000"
      QUESTION_PRARAM = "?xtr=Emf00100&NLS=JP"
      PASSWORD_PARAM = "?xtr=Emf00005&NLS=JP"
      MENU_PARAM = "?xtr=Emf02000&NLS=JP"

      def login
        page = agent.get(page_url(LOGIN_PARAM))
        form = page.form_with(name: "FORM1")
        form.action = action_url(LOGIN_PARAM)
        form["KeiyakuNo"] = @number

        page = form.submit
        loop do
          case page.uri.to_s
          when page_url(QUESTION_PRARAM)
            page = answer_question(page)
          when page_url(PASSWORD_PARAM)
            page = input_password(page)
          when page_url(MENU_PARAM)
            break
          else
            raise "Login failed"
          end
          sleep(0.3)
        end
        page
      end

      def details
        tables = menu_page.root.xpath("//table[5]//table[3]//table//table//table")
        balance = tables[0].css('tr')[3].css('td')[1].text.strip
        cols  = tables[1].css('tr')[1..-1]
        [].tap do |details|
          cols.reverse.each do |col|
            tds = col.css('td')
            detail = Hashie::Mash.new({
              date: tds[0].text,
              draw: tds[1].text,
              deposit: tds[2].text,
              subject: tds[3].text,
              balance: balance,
            })
            details << detail
            balance = prev_balance(balance, detail[:draw], detail[:deposit])
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

      def answer_question(page)
        asked_question = get_question(page)
        prepared_question = @questions.select { |secret_question|
          secret_question[:question] == asked_question
        }.first

        if prepared_question
          form = page.form_with(name: "FORM1")
          form.action = action_url(QUESTION_PRARAM)
          form["rskAns"] = prepared_question[:answer]

          next_page = form.submit
          if next_page.uri.to_s == page_url(QUESTION_PRARAM)
            next_question = get_question(next_page)
            if asked_question == next_question
              raise "Wrong answer for the question '#{asked_question}'"
            end
          end
        else
          raise "Unexpected question '#{asked_question}'"
        end
        next_page
      end

      def input_password(page)
        form = page.form_with(name: "FORM1")
        form.action = action_url(PASSWORD_PARAM)
        form["Anshu1No"] = @pin
        form.submit.tap do |next_page|
          raise "Wrong password" if next_page == page_url(PASSWORD_PARAM)
        end
      end

      def get_question(page)
       page.root.xpath("//table[7]/tr[2]/td[2]/div").text
      end

      def menu_page
        @menu_page ||= login
      end

      def page_url(param)
        "https://web4.ib.mizuhobank.co.jp/servlet/mib#{param}"
      end

      def action_url(param)
        "https://web4.ib.mizuhobank.co.jp:443/servlet/mib#{param}"
      end

      def prev_balance(balance, draw, deposit)
        balance_value = balance.gsub(/,/, "").to_i
        draw_value = draw.gsub(/,/, "").to_i
        deposit_value = deposit.gsub(/,/, "").to_i

        prev_balance_value = balance_value + draw_value - deposit_value
        prev_balance_value.humanize
      end
    end
  end
end
