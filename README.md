# helmet = HEaLthcare METrics

[![Code Climate](https://codeclimate.com/repos/554426f26956804030009d14/badges/fb6d8a2d9aa72673eb66/gpa.svg)](https://codeclimate.com/repos/554426f26956804030009d14/feed)  [![Build Status](https://travis-ci.org/HealthAPI/helmet.svg)](https://travis-ci.org/HealthAPI/helmet)  [![devDependency Status](https://david-dm.org/HealthAPI/helmet/dev-status.svg)](https://david-dm.org/HealthAPI/helmet#info=devDependencies)  [![Test Coverage](https://codeclimate.com/repos/554426f26956804030009d14/badges/fb6d8a2d9aa72673eb66/coverage.svg)](https://codeclimate.com/repos/554426f26956804030009d14/feed)

* [Context](https://github.com/HealthAPI/helmet/tree/master#context)
* [Market Forces & Industry Landscape](https://github.com/HealthAPI/helmet/tree/master#market-forces)
* [The Product](https://github.com/HealthAPI/helmet/tree/master#the-product)
* [How It Works](https://github.com/HealthAPI/helmet/tree/master#how-it-works)
* [Starting Points](https://github.com/HealthAPI/helmet/tree/master#starting-points)
* [Demo](https://github.com/HealthAPI/helmet/tree/master#demo)


### Context

Over the past 5 years, the healthcare industry has undergone a large technology transformation.  Doctors and hospitals have slowly been transitioning away from pen-and-paper medical records towards their modern electronic counterpart.  A large milestone was passed in 2014: over 50% of the country's doctors now use an electronic system to document their patients' medical care.  This number countinues to climb.

As a result, there is now more electronic health data available for analysis than ever before, and organizations have started using this data to make smarter decisions.  Especially in the insurance portion of the industry, companies are now using this information to help predict future healthcare risks for their subscribers.  Medicare has developed something called the [HCC](https://www.cms.gov/Medicare/Health-Plans/MedicareAdvtgSpecRateStats/downloads/evaluation_risk_adj_model_2011.pdf) model, which takes a disease-based approach to help predict future complications of specific chronic conditions; Johns Hopkins has developed their own [ACG](http://acg.jhsph.org/) model that takes a patient-specific approach to the same problem; New York University has developed their own [Emergency Department Algorith](http://www.wsha.org/files/169/NYU_Classification_System_for_EDVisits.pdf) in an attempt to lower the number of preventative visits to the emergency room; and the list goes on.

These models are not simple.  With perhaps the only exception being the actuarial portion of the healthcare insurance business, complex data science is completely new to the industry.

### Market Forces

At the same time, we're seeing a completely new level of innovation surrounding healthcare software.  The availability of this new electronic data, combined with the willingness of CMS (Centers for Medicaid/Medicare Services) to actually expose this data via sites like [Healthdata.gov](http://www.healthdata.gov/), has helped to attract more developers into the healthcare space than ever before.  While data security is still a looming challenge for any healthcare startup, there is now less and less bureaucratic red tape surrounding healthcare technology.  **TL/DR: More developers are building healthcare apps today than at any time prior.**

These new algorithms/methodologies aren't just stuck somewhere in an ivory tower, either.  They are already being put to use.  Hospitals and clinics are using these predictive methodologies to help identify patients in need of proactive intervention.  But perhaps even more importantly, **insurance companies have began using these algorithms to help determine physician compensation.**  To take a simplified example, a physician will earn a higher level of reimbursement from an insurance company if he/she can keep the total risk score of their patient population under a certain threshold.

This all boils down to a simple point: ***The results of these new/advanced algorithms are in high demand by healthcare organizations, and the ability to implement these algorithms into their product will become a minimum price of entry for any new healthcare applications.***

# The Product

The proposed product is simple: an API that allows healthcare developers to easily incorporate these complex metrics into their application, without having to hire an entire data science team to do so.

In one way or another, the results of these algorithms/models matter to *everyone*.  For insurance companies, they matter because they help project future costs.  For doctors, they matter because they influence physician compensation.  For patients, they matter because they can indicate patient's likeliness to become seriously ill.  ***Essentially, if you're building a new healthcare application for any audience in the industry, you will need to include these metrics in your product.***

### *More context...*

Since the availability of electronic health data is still relatively new, the majority of the most-used algorithms today rely simply on "claims data".  Prior to an EMR (Electronic Medical Record), the only way for an insurance company to identify care given to their members was when they got the bill for it, i.e. the claim.  However, in adherence with popular compensation models at the time, these insurance claims rarely included the *outcome* of this care.  For example, if a physician orders some bloodwork for a patient, the insurance company would get two bills: one for the blood draw at the physician's office, and another one from the lab company for running the actual tests.  Niether of those bills could possibly include the *results* of the test, and as a result, insurance companies were forced to build the majority of their algorithms based primarily upon boolean data points.

 > Has the patient been diagnosed with diabetes? **Yes**

 > Has the patient received proper insulin medication? **Yes**

 > Has the patient received a blood sugar check within the last 6 months? **No**

These data points are then feed into the algorithm, and the result is often times referred to as a *risk score*.

### How It Works

Our product will provide healthcare developers with an easy way to integrate the results of these complex algorithms into their product.  We will provide a robust API that will allow applications to send a pre-defined set of data points, and in return they will receive the final *risk score* or metric from the algorithm identified in the request.

A sample request to retrieve the output of the HCC model for a specific patient could look something like the following:

```javascript
{
  "request_id": "1234567890",
  "account_id": "123456",
  "account_key": "...",
  "request_type": "HCC",
  "data": {
    "id": "d769d282f37a3be76857c626f88e3946fdf1e43f",
    "gender": "male",
    "dob": "11/13/1987",
    "race": "white",
    "ethnicity": "non-hispanic",
    "model_data": {
      "disease_code": "250.01",
      "diagnosis_date": "02/21/1991",
      "last_office_visit": "03/25/2014"
    },
    "__comments": "some random comments or something"
  }
}
```

And a sample response to the above request could look something like this:

```javascript
{
  "request_id": "1234567890",
  "account_id": "123456",
  "account_key": "...",
  "request_type": "HCC",
  "data": {
    "hcc_score": "13.2",
    "hcc_level_abbr": "High Risk",
    "hcc_level_full": "Patient is at high risk for diabetic complications and should be contacted immediately."
  }
}
```

This will enable any healthcare application to incorporate high levels of clinical intelligence into their product, without having to do any of the heavy lifting themselves.

### Starting points

 > [View the project issues](https://github.com/HealthAPI/helmet/issues) to follow the discussion on overall strategy and starting points.


Relying heavily on both industry experience and statistical modeling expertise, we can begin by identifying the top 5-10 most prevalent algorithms/models/methodologies across the industry.  We should prioritize our model selection/build based on the following criteria:

1. **Current/Future Industry Adoption** - are people using this algorithm now?  Will they be in the future?
2. **Implications of Algorithm** - What do the results of this algorithm actually mean, and how are the results applied?

  > preference should be given to those algorithms which have a financial implication to the largest potential audience.  For example, an algorithm whose results carry heavy weight in the calculation of physician compensation should be prioritized above an algorithm that helps research-based clinicians identify target potential trial applicants.

3.  **Implementation Complexity** - How difficult is the model to build?  How difficult is it to run?

# Demo

*coming soon...*
