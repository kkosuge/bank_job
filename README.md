# BankJob

銀行口座から預金情報を取ってくるライブラリです。  
http://blog.kksg.net/posts/komono2

## Installation

```
git clone git@github.com:kkosuge/bank_job.git
cd bank_job
rake install
```

## Usage

### SMBC

```ruby
require 'bank_job'
require 'bank_job_smbc'

bj = BankJob.new

bj.register do |bank|
  bank.strategy = BankJob::Strategy::SMBC.new
  bank.number   = '0123456789'
  bank.pin      = '01234'
end

p bj.agents.first.deposits #=> 500,000,000円
```

### Mizuho

```ruby
require 'bank_job'
require 'bank_job_mizuho'

bj = BankJob.new

bj.register do |bank|
  bank.strategy = BankJob::Strategy::Mizuho.new
  bank.number   = '0123456789'
  bank.pin      = 'password'
  bank.quetions = [
    { question: '中学校の時のクラブ活動は何ですか（○○部、○○クラブ）', answer: '○○部' },
    { question: '父親の誕生日はいつですか（例：１２月２５日）',       answer: '１２月２５日' },
    { question: '母親の誕生日はいつですか（例：５月１４日）',         answer: '５月１４日' },
  ]
end

p bj.agents.first.deposits #=> 500,000,000円
```

### Yucho

```ruby
require 'bank_job'
require 'bank_job_yucho'

bj = BankJob.new

bj.register do |bank|
  bank.strategy = BankJob::Strategy::Yucho.new
  bank.number   = '0123456789012'
  bank.pin      = 'password'
  bank.quetions = [
    { question: '最も好きな動物は何ですか？', answer: '...' },
    { question: '最も好きな花は何ですか？',   answer: '...' },
    { question: '座右の銘は何ですか？',       answer: '...' },
  ]
end

p bj.agents.first.deposits #=> 500,000,000円
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
