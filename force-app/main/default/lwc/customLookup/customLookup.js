import { LightningElement, wire, api, track } from 'lwc';
import fetchRecords from '@salesforce/apex/CustomLookupController.fetchRecords';
import fetchRecentlyViewed from '@salesforce/apex/CustomLookupController.fetchRecentlyViewed';

const DELAY = 500;

export default class ReusableLookup extends LightningElement {
    @api label = "Related to:";
    @api required;
    @api disabled = false;
    @api placeholder = "Search for contact...";
    @api iconName = "standard:contact";
    @api sObjectApiName = "Contact";
    @api otherFieldApiName = "Email";
    @api filterField;
    @api filterValue;
    @api records = null;

    keepListboxOpen = false;
    loading = false;    
    @api searchKey = "";
    selectedRecordId;
    selectedRecordName;

    handleFocus(event) {
      this.keepListboxOpen = false;
      this.searchKey = event.target.value;
      if (this.searchKey.length == 0) {
        const sObjectApiName = this.sObjectApiName;
        const otherFieldApiName = this.otherFieldApiName;
        const filterField = this.filterField;
        const filterValue = this.filterValue;        
        fetchRecentlyViewed({ sObjectApiName: sObjectApiName, otherFieldApiName: otherFieldApiName, filterField: filterField, filterValue: filterValue})
        .then((result) => {
          if (result && result.length) {
            this.records = result;
            console.log(Object.values(result));
          } else {
            this.records = null;
          }        
        }); 
      }
    }

    @api handleInputBlur(event) {
      if (!this.keepListboxOpen) {
        this.searchKey = '';
        this.records = null;
      }
    }    

    @api handleBlur(event) {
      this.searchKey = '';
      this.records = null;
      this.keepListboxOpen = false;
    }
    
    @api handleMouseDown(event) {
      this.keepListboxOpen = true;
    }

    handleKeyChange(event) {
        window.clearTimeout(this.delayTimeout);
        if (event.target.value) {
          this.loading = true;
          const searchKey = event.target.value;
          const sObjectApiName = this.sObjectApiName;
          const otherFieldApiName = this.otherFieldApiName;
          const filterField = this.filterField;
          const filterValue = this.filterValue;
          this.delayTimeout = setTimeout(() => {
            fetchRecords({ searchKey: searchKey, sObjectApiName: sObjectApiName, otherFieldApiName: otherFieldApiName, filterField: filterField, filterValue: filterValue })
              .then((result) => {
                if (result && result.length) {
                  this.hasRecords = true;
                  this.loading = false;
                  this.records = result;
                  console.log(Object.values(result));
                } else {
                  this.loading = false;
                  this.records = null;
                }
              });
          }, DELAY);
        } else {
          this.records = null;
          this.hasRecords = true;
          this.loading = false;
        }
      }

    get isValueSelected() {
        return this.selectedRecordId;
    }

    //handler for selection of records from lookup result list
    handleSelect(event) {
      let selectedRecord = {
          name: event.currentTarget.dataset.name,
          detail: event.currentTarget.dataset.detail,
          id: event.currentTarget.dataset.id
      };
      this.selectedRecordId = selectedRecord.id;
      this.selectedRecordName = selectedRecord.name;
      this.records = null;
      // Creates the event
      const selectedEvent = new CustomEvent('valueselected', {
          detail: selectedRecord.id
      });
      //dispatching the custom event
      this.dispatchEvent(selectedEvent);
    }

    //handler for deselection of the selected item
    handleDeselect() {
      this.selectedRecordId = "";
      this.selectedRecordName = "";
      const deselectedEvent = new CustomEvent('valuedeselected', {
        detail: ""
      });
      //dispatching the custom event
      this.dispatchEvent(deselectedEvent);        
    }    

}