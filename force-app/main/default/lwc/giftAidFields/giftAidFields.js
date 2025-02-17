import { LightningElement, api } from 'lwc';

export default class GiftAidFields extends LightningElement {

    @api recordId;
    @api objectApiName;
    isLoading = false;

    handleClick(event) {
        event.preventDefault();
        this.isLoading = true;
        this.template.querySelector("lightning-record-edit-form").submit();
    }

    handleSuccess(event) {
        this.isLoading = false;
    }

}