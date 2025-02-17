import { LightningElement, api, wire } from 'lwc';
import generateLink from '@salesforce/apex/ImageUploadHandler.generateLink';
import deletePhoto from '@salesforce/apex/ImageUploadHandler.deletePhoto';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import PHOTO_URL from '@salesforce/schema/Lead.Photo_URL__c';
import { RefreshEvent } from 'lightning/refresh';

const fields = [PHOTO_URL];

export default class UploadProfilePhotoContact extends LightningElement {

  @api recordId;
  @api objectApiName;
  contentVersionId = '';
  isLoading = false;


  @wire(getRecord, { recordId: '$recordId', fields })
  lead;

  get profilePhotoUploaded() {
    return this.photoURL;
  }

  get photoURL() {
    return getFieldValue(this.lead.data, PHOTO_URL);
  }

  generateLink() {
    generateLink({ recordId: this.recordId, contentVersionId: this.contentVersionId })
      .then(result => {
        this.isLoading = false;
        this.dispatchEvent(new RefreshEvent());
      }) 
  }

  deletePhoto() {
    deletePhoto({ recordId: this.recordId })
      .then(result => {
        this.isLoading = false;
        this.dispatchEvent(new RefreshEvent());
      })
  }

  handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;
    if (uploadedFiles && uploadedFiles.length > 0){   
        this.contentVersionId = event.detail.files[0].contentVersionId;
        this.isLoading = true;
        this.generateLink();
    }
  }

  handleDelete(event) {
    this.isLoading = true;
    this.deletePhoto();
  }

}