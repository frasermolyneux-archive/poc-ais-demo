# POC - __summary title__

Add a __Proof of concept summary__ here.

---

## Architecture

Add an __architecture diagram__ here.

List the __architecture components__ here.

---

## Further Considerations

Naturally, this is a limited architecture for the POC with many additional considerations required. Here are a few as a starting point:

List the __further architecture considerations__ here.

---

## POC Scenarios

List the __POC Scenarios__ here.

---

## KQL Examples

```kql
union *
| extend meta = case( 
    customDimensions.prop__properties has "trackedProperties", parse_json(tostring(customDimensions.prop__properties)).trackedProperties,
    customDimensions has "trackedProperties", todynamic(tostring(customDimensions.trackedProperties)), todynamic(customDimensions))
| where meta.InterfaceId == "ID_VTB02"
| where meta.LicensePlate == "HHH HHHH"
| where meta.MessageId == "24c9955c-f535-4f79-be8a-b9e45d47d180"
```

```kql
let operationIds = union *
| extend meta = case(
    customDimensions.prop__properties has "trackedProperties", parse_json(tostring(customDimensions.prop__properties)).trackedProperties,
    customDimensions has "trackedProperties", todynamic(tostring(customDimensions.trackedProperties)), todynamic(customDimensions))
| where meta.InterfaceId == "ID_VTB02"
| where meta.LicensePlate == "HHH HHHH"
| where meta.MessageId == "24c9955c-f535-4f79-be8a-b9e45d47d180"
| distinct operation_Id;
union * | where operation_Id in (operationIds) | order by timestamp asc 
```