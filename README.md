# helmet = Healthcare Metrics

[![Code Climate](https://codeclimate.com/repos/554426f26956804030009d14/badges/fb6d8a2d9aa72673eb66/gpa.svg)](https://codeclimate.com/repos/554426f26956804030009d14/feed)  [![Build Status](https://travis-ci.org/HealthAPI/helmet.svg)](https://travis-ci.org/HealthAPI/helmet)  [![Test Coverage](https://codeclimate.com/repos/554426f26956804030009d14/badges/fb6d8a2d9aa72673eb66/coverage.svg)](https://codeclimate.com/repos/554426f26956804030009d14/feed)  [![devDependency Status](https://david-dm.org/HealthAPI/helmet/dev-status.svg)](https://david-dm.org/HealthAPI/helmet#info=devDependencies)  [![Coverage Status](https://coveralls.io/repos/HealthAPI/helmet/badge.svg)](https://coveralls.io/r/HealthAPI/helmet)


### Context

Over the past 5 years, the healthcare industry has undergone a large technology transformation.  Doctors and hospitals have slowly been transitioning away from pen-and-paper medical records towards their modern electronic counterpart.  A large milestone was passed in 2014: over 50% of the country's doctors now use an electronic system to document their patients' medical care.  This number countinues to climb.

As a result, there is now more electronic health data available for analysis than ever before, and organizations have started using this data to make smarter decisions.  Especially in the insurance portion of the industry, companies are now using this information to help predict future healthcare risks for their subscribers.  Medicare has developed something called the [HCC](https://www.cms.gov/Medicare/Health-Plans/MedicareAdvtgSpecRateStats/downloads/evaluation_risk_adj_model_2011.pdf) model, which takes a disease-based approach to help predict future complications of specific chronic conditions; Johns Hopkins has developed their own [ACG](http://acg.jhsph.org/) model that takes a patient-specific approach to the same problem; New York University has developed their own [Emergency Department Algorith](http://www.wsha.org/files/169/NYU_Classification_System_for_EDVisits.pdf) in an attempt to lower the number of preventative visits to the emergency room; and the list goes on.

These models are not simple.  With perhaps the only exception being the actuarial portion of the healthcare insurance business, complex data science is completely new to the industry.

### Market Forces

At the same time, we're seeing a completely new level of innovation surrounding healthcare software.  The availability of this new electronic data, combined with the willingness of CMS (Centers for Medicaid/Medicare Services) to actually expose this data via sites like [Healthdata.gov](http://www.healthdata.gov/), has helped to attract more developers into the healthcare space than ever before.  While data security is still a looming challenge for any healthcare startup, there is now less and less bureaucratic red tape surrounding healthcare technology.  **TL/DR: More people are building healthcare apps than ever before.**

These new algorithms/methodologies aren't just stuck somewhere in an ivory tower, either.  They are already being put to use.  Hospitals and clinics are using these predictive methodologies to help identify patients in need of proactive intervention.  But perhaps even more importantly, **insurance companies have began using these algorithms to help determine physician compensation.**  To take a simplified example, a physician will earn a higher level of reimbursement from an insurance company if he/she can keep the total risk score of their patient population under a certain threshold.

This all boils down to a simple point: ***The results of these new/advanced algorithms are in high demand by healthcare organizations, and the ability to implement these algorithms into their product will become a minimum price of entry for any new healthcare applications.***

 
