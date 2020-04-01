# frozen_string_literal: true
require 'mastercard_currencyconversion'
class RatesController < ApplicationController
  include MasterCard::Security::OAuth
  include MasterCard::Core
  include MasterCard::Core::Model
  include MasterCard::Core::Exceptions
  include MasterCard::API::CurrencyConversion

  def index; end

  def new
    @rate = Rate.new
  end

  def initialize
    @rate.date = date
    @rate.curr = curr
    @rate.sum = sum
  end

  def create
    @rate = Rate.new(rate_params)
    if @rate.save
      redirect_to @rate, notice: 'Посчиталось, епта'
    else
      render root_path,  notice: 'Чет хуйня'
    end

    mcrate(@rate.date, @rate.curr, @rate.sum)
    @rate.mcamount = mcrate.response.get(data.crdhldBillAmt)
    @rate.mcrate = mcrate.response.get(data.conversionRate)
  end

  def show
    @rate = Rate.find(params[:id])
  end

  def mcrate(date, curr, sum)
    consumerKey = 'EFSrWArnQLR5J7XQ85AO7Kqt0KIbytH9R1Gt5W-n066b9f28!2627d9226b4e401ea54ce8ddacb3db4f0000000000000000' # You should copy this from "My Keys" on your project page
    keyFile = 'MS_Sandbox_API/Rocketbank_Currency_Converter-sandbox.p12' # e.g. /Users/yourname/project/sandbox.p12 | C:\Users\yourname\project\sandbox.p12
    keyAlias = 'keyalias' # For production: change this to the key alias you chose when you created your production key
    keyPassword = 'keystorepassword' # For production: change this to the key alias you chose when you created your production key
    auth = OAuth::OAuthAuthentication.new(consumerKey, keyFile, keyAlias, keyPassword)
    Config.setAuthentication(auth)
    Config.setDebug(true) # Enable http wire logging
    # This is needed to change the environment to run the sample code. For production: use Config.setSandbox(false)
    Config.setEnvironment('sandbox_mtf')

    begin
      mapObj = RequestMap.new
      mapObj.set('fxDate', date) # 2019-09-30
      mapObj.set('transCurr', curr)
      mapObj.set('crdhldBillCurr', 'USD')
      mapObj.set('bankFee', '0')
      mapObj.set('transAmt', sum)
      response = ConversionRate.query(mapObj)

      out(response, 'data.conversionRate'); #-->0.57
      out(response, 'data.crdhldBillAmt'); #-->13.11
    rescue APIException => e
      err("HttpCode: #{e.getHttpCode}")
      err("Message: #{e.getMessage}")
      err("ReasonCode: #{e.getReasonCode}")
      err("Message: #{e.getSource}")
    end
  end

  def out(response, key)
    puts "#key-->#{response.get(key)}"
  end

  def outObj(response, key)
    puts "#key-->#{response[key]}"
  end

  def err(message)
    puts message
  end

  def errObj(response, key)
    puts "#key-->#{response.get(key)}"
  end

  private

  def rate_params
    params.require(:rate).permit(:date, :sum, :curr)
  end
end
