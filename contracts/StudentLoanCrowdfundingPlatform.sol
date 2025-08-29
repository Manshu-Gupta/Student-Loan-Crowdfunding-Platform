// SPDX-License-Identifier: MIT
paymentsMade: 0,
lastPaymentMonth: 0,
withdrawn: false
});
emit StudentProfileCreated(studentCount, msg.sender, _fundingGoal);
studentCount++;
}


function contribute(uint _studentId) external payable whenNotPaused nonReentrant {
Student storage s = students[_studentId];
require(s.wallet != address(0), "Student not found");
require(s.amountRaised < s.fundingGoal, "Goal reached");
require(msg.value > 0, "Contribution must be > 0");


uint allowed = s.fundingGoal - s.amountRaised;
uint contribution = msg.value;
if (contribution > allowed) {
uint refund = contribution - allowed;
contribution = allowed;
payable(msg.sender).transfer(refund);
}


contributions[_studentId].push(Contribution({amount: contribution, claimed: false}));
s.amountRaised += contribution;
platformFees += (contribution * FEE_PERCENT) / 100;
emit ContributionMade(_studentId, msg.sender, contribution);
}


function withdrawFunds(uint _studentId) external nonReentrant {
Student storage s = students[_studentId];
require(msg.sender == s.wallet, "Not student");
require(!s.withdrawn, "Already withdrawn");
require(s.amountRaised >= s.fundingGoal, "Goal not reached");


s.withdrawn = true;
uint payout = s.amountRaised - (s.amountRaised * FEE_PERCENT) / 100;
payable(s.wallet).transfer(payout);
}


function reportIncome(uint _studentId, uint _incomeAmount) external whenNotPaused {
Student storage s = students[_studentId];
require(msg.sender == s.wallet, "Not student");
require(s.paymentsMade < s.paymentDurationMonths, "All payments done");


incomeReports[_studentId].push(IncomeReport({incomeAmount: _incomeAmount, isVerified: true}));
emit IncomeReported(_studentId, _incomeAmount);


_processIncomePayment(_studentId, _incomeAmount);
}


function _processIncomePayment(uint _studentId, uint _incomeAmount) internal nonReentrant {
Student storage s = students[_studentId];
require(s.paymentsMade < s.paymentDurationMonths, "Payments complete");


uint totalPayment = (_incomeAmount * s.incomeSharePercent) / 100;
uint contributorCount = contributions[_studentId].length;
require(contributorCount > 0, "No contributors");


uint sharePerContributor = totalPayment / contributorCount;
for (uint i = 0; i < contributorCount; i++) {
Contribution storage c = contributions[_studentId][i];
if (!c.claimed) {
payable(msg.sender).transfer(sharePerContributor);
c.claimed = true;
}
}


s.paymentsMade++;
emit IncomePaymentProcessed(_studentId, totalPayment);
}


function withdrawPlatformFees(address payable _to) external onlyOwner nonReentrant {
require(platformFees > 0, "No fees");
uint amount = platformFees;
platformFees = 0;
_to.transfer(amount);
}
}
