import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getGivingArmDetails from '@salesforce/apex/GivingArmController.getGivingArmDetails';

export default class GivingArm extends LightningElement {

    @api recordId;
    data;
    error;
    deepCloneData;    

    @wire(getGivingArmDetails, { acctId : '$recordId' })
    wiredGivingArmDetails({data, error}) {
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
            acct.Opportunities.forEach((opp) => {
                opp.oppCurrencyIsJPY = opp.CurrencyIsoCode == 'JPY';
                console.log(opp);
            })
        });
        console.log(deepCloneData);
    }

    viewGivingArm(event) {
        var acctId = event.target.dataset.id;
        var baseURL = window.location.origin;
        if (acctId) {
            window.open(baseURL + '/lightning/r/Account/' + acctId + '/view', '_blank');
        }
    } 
    
    viewOpp(event) {
        var oppId = event.target.dataset.id;
        var baseURL = window.location.origin;
        if (oppId) {
            window.open(baseURL + '/lightning/r/Opportunity/' + oppId + '/view', '_blank');
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