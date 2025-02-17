import { LightningElement, api, wire } from 'lwc';
import getPmtAmtInUSD from '@salesforce/apex/ConvertedPaymentAmtController.getPmtAmtInUSD';

export default class PaymentAmountInUSDDatedConversionRate extends LightningElement {
    @api recordId;
    data;
    error;
    labelText;
    @wire(getPmtAmtInUSD, { pmtId : '$recordId' }) 
    wiredClass({data, error}) {
        if (data) {
            this.data = (Math.round(data*100)/100).toFixed(2);
            let formattedAmt = data.toLocaleString('en', {minimumFractionDigits: 2});
            this.labelText = 'Payment Amount in USD (Dated): $' + formattedAmt;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }    
}