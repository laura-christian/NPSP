({ 
  invoke: function (component, event, helper) {
    var navService = component.find("navService");
    var recordId = component.get("v.recordId");
    var objectName = component.get("v.sObject");
    var mode = component.get("v.mode").toLowerCase();
    var pageReference = {
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        objectApiName: objectName,
        actionName: "view"
      }
    };
    navService.navigate(pageReference);
  }
});