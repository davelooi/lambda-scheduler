def ping(event:, context:)
  require 'net/http'
  uri = URI('https://data.exchange.coinjar.com/products/BTCAUD/ticker')
  response = Net::HTTP.get_response(uri)

  if response.code == '200'
    require 'json'
    body = JSON.parse(response.body)
    tick = {
      currency_pair: 'BTCAUD',
      current_time: body.fetch('current_time'),
      last: body.fetch('last'),
      bid: body.fetch('bid'),
      ask: body.fetch('ask')
    }.to_json
    puts "tick=#{tick}"
  else
    puts "code=#{response.code}"
  end
end

def iterate(event:, context:)
  idx = event.dig('iterator', 'index') + 1
  puts "idx=#{idx}"

  require 'aws-sdk-lambda'
  client = Aws::Lambda::Client.new(region: ENV.fetch('REGION'))
  resp = client.invoke({
    function_name: "lambda-scheduler-#{ENV.fetch('STAGE')}-ping",
    invocation_type: 'Event',
    payload: { index: idx }.to_json
  })

  {
    index: idx,
    continue: idx < event.dig('iterator', 'count'),
    count: event.dig('iterator', 'count')
  }
end
