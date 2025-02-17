import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import convertLead from '@salesforce/apex/ConvertLeadController.convertLead';

export default class ConvertLead extends LightningElement {

  _recordId;
  @api selectedOption;
  @api collapseListbox = false;
  @api selectedContactId = '';
  @api selectedHouseholdId = '';
  @track contactLookupDisabled = true;
  @track householdLookupDisabled = true;
  @api affiliateOrgId = '';
  @track affiliateOrgSelected = false;
  @api affiliationType = '';
  @api primaryAffiliation = false;
  @api convertedLeadContactId = '';
  @api isLoading = false;

  @api set recordId(value) {
    this._recordId = value;
  }

  get recordId() {
    return this._recordId;
  }

  handleCancel(){
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  get conversionOptions() {
    return [
      { label: 'Create new contact', value: 'New' },
      { label: 'Merge lead to existing contact', value: 'Merge' },      
      { label: 'Add converted lead to existing household', value: 'Add' }
    ];
  }

  get contactLookupDisabled() {
    return this.selectedOption == 'Merge' ? false : true;
  } 

  get householdLookupDisabled() {
    console.log('Getter for household lookup fired');
    return this.selectedOption == 'Add' ? false : true;
  }

  handleConversionOptionSelection(event) {
    event.target.checkValidity();
    event.target.reportValidity();     
    this.selectedOption = event.target.value;
    if (this.selectedOption == 'Merge') {    
      this.contactLookupDisabled = false;
      this.householdLookupDisabled = true;
    }
    else if (this.selectedOption == 'Add') {   
      this.contactLookupDisabled = true;
      this.householdLookupDisabled = false;
    } 
    else if (this.selectedOption == 'New' || this.selectedOption == '' || this.selectedOption == null || this.selectedOption == undefined) {    
      this.contactLookupDisabled = true;
      this.householdLookupDisabled = true;
    }          
  }

  get affiliationTypes() {
    return [
        { label: 'Alumnus/a', value: 'Alumnus/a' },
        { label: 'C/F Liaison', value: 'C/F Liaison' },
        { label: 'Chapter Volunteer', value: 'Chapter Volunteer' },
        { label: 'Chapter Leader', value: 'Chapter Leader' },
        { label: 'Chapter Core Committee Member', value: 'Chapter Core Committee Member' },
        { label: 'Chapter Leader Emeritus', value: 'Chapter Leader Emeritus' },
        { label: 'Employee', value: 'Employee' },
        { label: 'Giving Arm', value: 'Giving Arm' }
    ];
  }

  handleValueSelectedContact(event) {
    this.selectedContactId = event.detail;
    console.log(this.selectedContactId);
  }

  handleValueDeselectedContact(event) {
    this.selectedContactId = "";
  }    

  handleValueSelectedHouseholdAcct(event) {
    this.selectedHouseholdId = event.detail;
  }

  handleValueDeselectedHouseholdAcct(event) {
    this.selectedHouseholdId = "";
  }     

  handleValueSelectedAffiliateOrg(event) {
    this.affiliateOrgId = event.detail;
    this.affiliateOrgSelected = true;
  }

  handleValueDeselectedAffiliateOrg(event) {
    this.affiliateOrgId = "";
    this.affiliateOrgSelected = false;
  }  

  get affiliateOrgSelected() {
    return (this.affiliateOrgId == null || this.affiliateOrgId == '' || this.affiliateOrgId == undefined) ? false : true;
  }

  handleSelectionAffiliationType(event) {
    event.target.checkValidity();
    event.target.reportValidity()
    this.affiliationType = event.target.value;
    console.log(this.affiliationType);
  }

  handleSubmit(event) {
    var formValuesValid = 
    [...this.template.querySelectorAll('lightning-combobox')]
    .reduce((validSoFar, comboboxInput) => {
        comboboxInput.reportValidity();
        return validSoFar && comboboxInput.checkValidity();
    }, true);
    if (formValuesValid) {    
      const leadId = this._recordId;
      const contactId = this.selectedContactId;
      const householdId = this.selectedHouseholdId;
      const affiliateOrgId = this.affiliateOrgId;
      const affiliationType = this.affiliationType;
      const primaryAffiliation = this.primaryAffiliation;
      var affilType = document.getElementById('affilType');
      this.isLoading = true;          
      convertLead({ leadId: leadId, contactId: contactId, householdId: householdId, affiliateOrgId: affiliateOrgId, affiliationType: affiliationType, primaryAffiliation: primaryAffiliation })
      .then((result)=>{
          this.convertedLeadContactId = result;
          this.dispatchEvent(new CloseActionScreenEvent());
          var baseURL = window.location.origin;
          window.open(baseURL + '/lightning/r/Contact/' + this.convertedLeadContactId + '/view', '_self');
      });
    }
  }

}