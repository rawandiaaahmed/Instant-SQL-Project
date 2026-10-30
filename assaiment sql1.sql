-- List all students who enrolled before 2023 and still have 'Active' status.
-- Sort alphabetically.
SELECT *
FROM Students
WHERE EnrollDate < '2023-01-01' AND Status = 'Active'
ORDER BY StudentName ASC;

-- Find all courses with 'Python' or 'SQL' anywhere in the course name,
-- priced under 4000 EGP.
SELECT *
FROM Courses
WHERE (CourseName LIKE '%Python%'
       OR CourseName LIKE '%SQL%')
  AND Price < 4000;

-- Show top 3 highest payments for each method (Credit Card, Cash, Online).
-- Use separate queries.
SELECT TOP 3 *
FROM Payments
WHERE Method IN ('Credit Card', 'Cash', 'Online')
ORDER BY Amount DESC;

-- Find all enrollments where EnrollStatus is NOT 'Completed' and NOT 'Cancelled'.
-- Include only 2024 enrollments.
SELECT *
FROM Enrollments
WHERE EnrollStatus NOT IN ('Completed', 'Cancelled')
  AND EnrollDate BETWEEN '2024-01-01' AND '2024-12-31';

-- For all attendance records, show AttendanceID, EnrollmentID, AttendStatus,
-- and replace NULL Notes with 'No Remarks'.
-- Filter to only 'Absent' records.
SELECT AttendenceID,
       EnrollmentID,
       AttendStatus,
       ISNULL (Notes , 'No Remarks') AS Notes
FROM Attendence
WHERE AttendStatus = 'Absent';

-- Write a query to find ALL leads from 2024 that:
--   - Have no campaign (CampaignID IS NULL)
--   - Come from 'Social Media' or 'Referral' source
--   - AND status is 'New' or 'Interested'
-- Sort by CreatedDate newest first.

SELECT *
FROM Leads
WHERE CampaignID IS NULL
  AND Source IN ('Social Media', 'Referral')
  AND Status IN ('New', 'Interested')
  AND CreatedDate >= '2024-01-01'
  AND CreatedDate < '2025-01-01'
ORDER BY CreatedDate DESC;
-- Revenue Leaderboard:
-- From the Payments table, show Method, total revenue (SUM of Amount)
-- as TotalRevenue, and average payment (AVG of Amount) as AvgPayment.
-- Filter to Status = 'Paid' payments only.
-- Sort by TotalRevenue descending.
SELECT
    Method,
    SUM(Amount) AS TotalRevenue,
    AVG(Amount) AS AvgPayment
FROM Payments
WHERE Status = 'Paid'
GROUP BY Method
ORDER BY TotalRevenue DESC;

-- Agent Lead Report:
-- From the Leads table, show AgentID and COUNT(LeadID) as TotalLeads.
-- Filter to leads with Status IN ('New', 'Interested').
-- Only include agents with more than 5 leads (use HAVING).
-- Sort by TotalLeads descending.

SELECT
    AgentID,
    COUNT(LeadID) AS TotalLeads
FROM Leads
WHERE Status IN ('New', 'Interested')
GROUP BY AgentID
HAVING COUNT(LeadID) > 5
ORDER BY TotalLeads DESC;

-- Attendance Summary:
-- From the Attendance table, show AttendStatus and
-- COUNT(AttendanceID) as TotalSessions.
-- Group by AttendStatus.
-- Sort by TotalSessions descending.

SELECT
    AttendStatus,
    COUNT(AttendenceID) AS TotalSessions
FROM Attendence
GROUP BY AttendStatus
ORDER BY TotalSessions DESC;

-- Campaign Efficiency Report:
-- From the Leads table, show CampaignID, COUNT(LeadID) as TotalLeads,
-- MIN(CreatedDate) as FirstLeadDate, MAX(CreatedDate) as LastLeadDate.
-- Exclude leads with no campaign (CampaignID IS NOT NULL).
-- Only campaigns with 5 or more leads (use HAVING).
-- Sort by TotalLeads descending.

SELECT
    CampaignID,
    COUNT(LeadID) AS TotalLeads,
    MIN(CreatedDate) AS FirstLeadDate,
    MAX(CreatedDate) AS LastLeadDate
FROM Leads
WHERE CampaignID IS NOT NULL
GROUP BY CampaignID
HAVING COUNT(LeadID) >= 5
ORDER BY TotalLeads DESC;
