import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getGivingArmHouseholdDetails from '@salesforce/apex/GivingArmController.getGivingArmHouseholdDetails';

export default class GivingArmHousehold extends LightningElement {

    @api recordId;
    data;
    error;
    deepCloneData;

    @wire(getGivingArmHouseholdDetails, { acctId : '$recordId' })
    wiredOppTeam({data, error}) {
        if (data) {
            this.data = data;
            this.deepCloneData = JSON.parse(JSON.stringify(data));
            this.addPropsToData(this.deepCloneData);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    addPropsToData(deepCloneData){
        deepCloneData.forEach((acct) => {
            acct.acctCurrencyIsJPY = acct.CurrencyIsoCode == 'JPY';
            console.log(acct);
        });
    }    
    
 
    viewHousehold(event) {
        var acctId = event.target.dataset.id;
        var baseURL = window.location.origin;
        if (acctId) {
            window.open(baseURL + '/lightning/r/Account/' + acctId + '/view', '_blank');
        }
    } 

    viewRMUserRecord(event) {
        var userId = event.target.dataset.id;
        var baseURL = window.location.origin;
        if (userId) {
            window.open(baseURL + '/lightning/r/User/' + userId + '/view', '_blank');
        }
    } 
}