import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOppTeamMembers from '@salesforce/apex/OpportunityTeamMemberController.getOppTeamMembers';
import insertOppTeamMember from '@salesforce/apex/OpportunityTeamMemberController.insertOppTeamMember';
import { refreshApex } from '@salesforce/apex';
import OPPORTUNITYTEAMMEMBER_OBJECT from '@salesforce/schema/OpportunityTeamMember';
import OPPORTUNITYID_FIELD from '@salesforce/schema/OpportunityTeamMember.OpportunityId';
import USERID_FIELD from '@salesforce/schema/OpportunityTeamMember.UserId';
import TEAMMEMBERROLE_FIELD from '@salesforce/schema/OpportunityTeamMember.TeamMemberRole';

export default class AddOpportunityTeamMember extends LightningElement {
    
    @api recordId;
    data;
    error;    
    recordCount;

    @wire(getOppTeamMembers, { oppId : '$recordId' })
    wiredOppTeam({data, error}) {
        if (data) {
            this.data = data;
            this.recordCount = Object.values(this.data).length;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }      


    viewRelatedList(event) {
        var baseURL = window.location.origin;
        window.open(baseURL + '/lightning/r/Opportunity/' + this.recordId + '/related/OpportunityTeamMembers/view', '_self');
    }

    viewRecord(event) {
        var userId = event.target.dataset.id;
        var baseURL = window.location.origin;
        if (userId) {
            window.open(baseURL + '/lightning/r/User/' + userId + '/view', '_blank');
        }
    } 
    
    @track isModalOpen = false;
    openModal() {
      this.isModalOpen = true;
    }
    closeModal() {
      this.isModalOpen = false;
    }

    @track isLoading = false;
    showSpinner() {
        this.isLoading = true;
    }
    hideSpinner() {
        this.isLoading = false;
    }    

    opportunityTeamMemberObject = OPPORTUNITYTEAMMEMBER_OBJECT;
    userIdField = USERID_FIELD;
    teamMemberRoleField = TEAMMEMBERROLE_FIELD;
    opportunityIdField = OPPORTUNITYID_FIELD;

    handleSubmit(event) {
        event.preventDefault();
        this.showSpinner();
        const fields = event.detail.fields;
        var oppId = fields.OpportunityId;
        var userId = fields.UserId;
        var role = fields.TeamMemberRole;
        insertOppTeamMember({ oppId : oppId, userId : userId, role : role })
        .then((result)=>{
            console.log(result);
            this.hideSpinner();
        })
        .then((result) => {
            this.closeModal();
            location.reload(true);            
        })
        .catch((error) => {
            this.hideSpinner();
            this.error = error;
            console.log(error);
        });
    }

}