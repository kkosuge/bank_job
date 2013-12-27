require 'bank_job/strategy'

module BankJob
  module Strategy
    class Yucho
      include BankJob::Strategy

      LOGIN_URL = 'https://direct.jp-bank.japanpost.jp/tp1web/U010101SCK.do'

      QUESTION_PATHS = %w(U330102SCR U330202SCR)
      PASSWORD_PATH  = 'U010902SCR'
      MENU_PATH      = 'U030105SCR'

      DETAIL_IGNORE_KEYWORDS = %w(通帳の現在高 通帳未記入金合計)
      DETAIL_TABLE_COLUMNS = [:date, :deposit, :draw, :subject, :balance].freeze

      def details
        cols = detail_page.root.
          xpath('//table[@class="infocell nbsp10 tablelayoutauto"]').
          first.css('tr')
        [].tap do |details|
          cols.each do |col|
            next if ignore_column?(col)
            details << detail(col)
          end
        end
      end

      def deposit
        details.last.balance
      end

      def deposits
        deposit
      end

      private

      def detail_page
        return @detail_page if @detail_page
        page = detail_menu_page
        form = page.form_with(name: 'submitData')
        form.radiobutton_with(value: '03', name: 'shoukaiTaishouSentaku').check
        @detail_page = submit_with(page, '次へ')
      end

      def detail_menu_page
        menu_page = login
        submit_with(menu_page, '入出金明細照会')
      end

      def login
        page = agent.get(LOGIN_URL)
        input_number(page)
        page = submit_with(page, '次へ')

        loop do
          case form_path(page)
          when *QUESTION_PATHS
            page = answer_question(page)
          when PASSWORD_PATH
            page = input_password(page)
          when MENU_PATH
            break
          else
            raise "Login failed"
          end
          sleep(0.3)
        end
        page
      end

      def form_path(page)
        page.uri.to_s.match(/tp1web\/([^\.]*)\.do/)[1]
      end

      def answer_question(page)
        asked_question = get_question(page)
        prepared_question = @questions.select { |secret_question|
          secret_question[:question] == asked_question
        }.first

        if prepared_question
          form = page.form_with(name: 'submitData')
          form['aikotoba'] = prepared_question[:answer]

          next_page = submit_with(page, '次へ')
          if QUESTION_PATHS.include?(form_path(next_page))
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

      def get_question(page)
        page.root.xpath('//*[@class="loginbox nbsp5"]//span[1]').first.text
      end

      def input_number(page)
        form = page.form_with(name: 'submitData')
        login_number = @number.tr('-', '')
        raise 'Invalid login number' if login_number.length < 13

        form['okyakusamaBangou1'] = login_number[0..3]
        form['okyakusamaBangou2'] = login_number[4..7]
        form['okyakusamaBangou3'] = login_number[8..12]
      end

      def input_password(page)
        form = page.form_with(name: 'submitData')
        form['loginPassword'] = @pin
        submit_with(page, 'ログイン').tap do |next_page|
          raise 'Wrong password' if form_path(next_page) == PASSWORD_PATH
        end
      end

      def submit_with(page, button_name)
        form = page.form_with(name: 'submitData')
        button_element = page.search("//input[contains(@value, '#{button_name}')]").first
        onclick = button_element.attr('onclick')

        form.action = onclick.match(/dcRequest\('[^']*','([^']*)'/)[1]
        form['event'] = onclick.match(/Array\('([^']*)'\),false/)[1]
        form.submit
      end

      def ignore_column?(col)
        return true if col.css('td').count < 5
        subject = col.css('td')[DETAIL_TABLE_COLUMNS.index(:subject)].text
        DETAIL_IGNORE_KEYWORDS.each do |ignore_keyword|
          return true if subject.include?(ignore_keyword)
        end
        false
      end

      def detail(col)
        tds = col.css('td')
        Hashie::Mash.new.tap do |detail|
          DETAIL_TABLE_COLUMNS.each_with_index do |name, column|
            detail[name] = tds[column].text
          end
        end
      end
    end
  end
end
