import { LightningElement, api, wire } from 'lwc';
import getGivingSummary from '@salesforce/apex/GivingSummaryInUSDController.getGivingSummary';

export default class GivingSummaryUSDDatedConversionRates extends LightningElement {
    @api recordId;
    @wire(getGivingSummary, { acctId : '$recordId' }) givingSummary

}