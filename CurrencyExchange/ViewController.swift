//
//  ViewController.swift
//  CurrencyExchange
//
//  Created by Brian Zhang on 10/20/21.
//

import UIKit
import SwiftyJSON
import SwiftSpinner
import Alamofire
import PromiseKit

class ViewController: UIViewController {
    
    let baseURL = "http://api.exchangeratesapi.io/v1/"
    let apiKey = "19ef5b4ececa3be5b81289d2e8a5a68f"
    
    @IBOutlet weak var fromPicker: UIPickerView!
    @IBOutlet weak var toPicker: UIPickerView!
    
    var currencies = ["USD", "CAD", "TWD", "CNY", "HKD", "JPY", "EUR", "GBP", "CHF", "IDR"]
    
    var fromCurrency: String = "USD"
    var toCurrency: String = "CAD"
    
    @IBOutlet weak var Rates: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fromPicker.dataSource = self
        fromPicker.delegate = self
        toPicker.dataSource = self
        toPicker.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getCurrencyOnline()
            .done { getCurrencyOnline in
                self.currencies = getCurrencyOnline
                self.fromPicker.reloadAllComponents()
                self.toPicker.reloadAllComponents()
                
                if let fromIdx = self.currencies.firstIndex(of: self.fromCurrency) {
                    self.fromPicker.selectRow(fromIdx, inComponent:0, animated:false)
                }
                if let toIdx = self.currencies.firstIndex(of: self.toCurrency) {
                    self.toPicker.selectRow(toIdx, inComponent:0, animated:false)
                }
            }
            .catch { _ in
                self.fromPicker.selectRow(0, inComponent:0, animated:true)
                self.toPicker.selectRow(0, inComponent:0, animated:true)
            }
    }
    
    func getCurrencyOnline() -> Promise<Array<String>>{
        
        return Promise<Array<String>>{seal -> Void in
            let url = baseURL + "symbols" + "?access_key=" + apiKey
            
            Alamofire.request(url).responseJSON{ response in
                switch response.result {
                case .success(let pass):
                    let currencies = JSON(pass)["symbols"].dictionaryValue.keys.sorted()
                    seal.fulfill(currencies)
                case .failure(let error):
                    print(error)
                    seal.reject(error)
                }
            }
        }
    }
    
    func getExchangeRate(_ fromCurrency: String, _ toCurrency: String) -> Promise<(Float,Float)>{
        
        return Promise<(Float,Float)>{seal -> Void in
            
            let url = baseURL + "latest" + "?access_key=" + apiKey + "&symbols=" + fromCurrency + "," + toCurrency
            
            Alamofire.request(url).responseJSON { response in
                switch response.result {
                case .success(let pass):
                    let rates = JSON(pass)["rates"]
                    let fromCurrencyRate = rates[fromCurrency].floatValue
                    let toCurrencyRate = rates[toCurrency].floatValue
                    seal.fulfill((fromCurrencyRate, toCurrencyRate))
                    
                case .failure(let error):
                    print("error")
                    seal.reject(error)
                }
                
            }
            
        }
    }
    
    @IBAction func getExchangeRate(_ sender: Any) {
        if fromCurrency == "" || toCurrency == ""{
            return
        }
        getExchangeRate(fromCurrency, toCurrency)
            .done { fromCurrencyRate, toCurrencyRate in
                self.Rates.text = "1 \(self.fromCurrency) = \(toCurrencyRate/fromCurrencyRate) \(self.toCurrency)"
                
            }
            .catch { error in
                print(error)
            }
    }
}

extension ViewController: UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }
}

extension ViewController: UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == fromPicker {
            self.fromCurrency = self.currencies[row]
        } else if pickerView == toPicker {
            self.toCurrency = self.currencies[row]
        }
    }
}



