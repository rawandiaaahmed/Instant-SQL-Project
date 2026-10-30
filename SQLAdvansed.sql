-- HW1 — Student Enrollment Summary
-- For each student, show:
--   StudentName, TotalCourses enrolled, TotalAmountPaid, LastEnrollDate.
SELECT
    s.StudentName,
    COUNT(e.CourseID) AS TotalCourses,
    SUM(e.EnrollmentID) AS TotalAmountPaid,
    MAX(e.EnrollDate) AS LastEnrollDate
FROM Students s
LEFT JOIN Enrollments e
    ON s.StudentID = e.StudentID
GROUP BY
    s.StudentID,
    s.StudentName;

-- HW2 — Agent Performance Report
-- For each sales agent, show:
--   AgentName, Region, TotalLeads,
--   ConvertedLeads (leads where Status = 'Enrolled'),
--   ConversionRate as a percentage (e.g. 33.3).
SELECT
    a.AgentName,
    a.Region,
    COUNT(l.LeadID) AS TotalLeads,
    SUM(CASE 
            WHEN l.Status = 'Enrolled' THEN 1 
            ELSE 0 
        END) AS ConvertedLeads,
    CAST(
        SUM(CASE 
                WHEN l.Status = 'Enrolled' THEN 1 
                ELSE 0 
            END) * 100.0
        / NULLIF(COUNT(l.LeadID), 0)
        AS DECIMAL(5,1)
    ) AS ConversionRate
FROM SalesAgents a
LEFT JOIN Leads l
    ON a.AgentID = l.AgentID
GROUP BY
    a.AgentID,
    a.AgentName,
    a.Region;

    -- HW3 — Course Popularity Report
-- For each course, show:
--   CourseName, Category, TotalEnrollments, TotalRevenue, TotalAttendanceSessions.
SELECT
    c.CourseName,
    c.Category,
    COUNT(DISTINCT e.EnrollmentID) AS TotalEnrollments,
    SUM(e.EnrollmentID) AS TotalRevenue,
    COUNT(a.AttendenceID) AS TotalAttendanceSessions
FROM Courses c
LEFT JOIN Enrollments e
    ON c.CourseID = e.CourseID
LEFT JOIN Attendence a
    ON e.EnrollmentID = a.EnrollmentID
GROUP BY
    c.CourseID,
    c.CourseName,
    c.Category;

-- HW4 — Unenrolled Leads Report
-- List all leads that were created but never resulted in an enrollment.
-- Show: LeadName, Source, AgentName, CreatedDate.

SELECT
    l.LeadName,
    l.Source,
    a.AgentName,
    l.CreatedDate
FROM Leads l
JOIN SalesAgents a
    ON l.AgentID = a.AgentID
WHERE NOT EXISTS (
    SELECT 1
    FROM Enrollments e
    WHERE e.EnrollmentID = l.LeadID
);
-- PROJECT Q1 — Revenue by Course Category
-- Month-over-month breakdown using Courses + Enrollments + Payments.
-- Show: Category, PaymentMonth (formatted as 'yyyy-MM'),
--       UniqueStudents, TotalEnrollments, TotalRevenue, AvgTicketSize.
-- Include only 'Paid' payments.
SELECT
    c.Category,
    FORMAT(p.PaymentDate, 'yyyy-MM') AS PaymentMonth,
    COUNT(DISTINCT e.StudentID) AS UniqueStudents,
    COUNT(DISTINCT e.EnrollmentID) AS TotalEnrollments,
    SUM(p.Amount) AS TotalRevenue,
    AVG(p.Amount) AS AvgTicketSize
FROM Courses c
JOIN Enrollments e
    ON c.CourseID = e.CourseID
JOIN Payments p
    ON e.EnrollmentID = p.EnrollmentID
WHERE p.Status = 'Paid'
GROUP BY
    c.Category,
    FORMAT(p.PaymentDate, 'yyyy-MM')
ORDER BY
    PaymentMonth,
    c.Category;

-- PROJECT Q2 — Student Journey Report
-- From lead source to enrollment to payment to attendance using all 8 tables.
-- Show: LeadName, Source as LeadSource, AgentName, CampaignName,
--       CourseName, EnrollDate, Amount as AmountPaid, AttendStatus.

SELECT
    l.LeadName,
    l.Source AS LeadSource,
    a.AgentName,
    c.CampaignName,
    co.CourseName,
    e.EnrollDate,
    p.Amount AS AmountPaid,
    att.AttendStatus
FROM Leads l
JOIN SalesAgents a
    ON l.AgentID = a.AgentID
JOIN Campaigns c
    ON l.CampaignID = c.CampaignID
JOIN Enrollments e
    ON l.LeadID = e.EnrollmentID
JOIN Courses co
    ON e.CourseID = co.CourseID
JOIN Payments p
    ON e.EnrollmentID = p.EnrollmentID
JOIN Attendence att
    ON e.EnrollmentID = att.EnrollmentID;

-- PROJECT Q3 — Campaign ROI Analysis
-- Budget vs revenue generated per campaign.
-- Tables: Campaigns + Leads + Enrollments + Payments.
-- Show: CampaignName, Channel, Budget, TotalLeads, TotalRevenue,
--       ROI (TotalRevenue / Budget rounded to 2 decimals).

SELECT
    c.CampaignName,
    c.Channel,
    c.Budget,
    COUNT(DISTINCT l.LeadID) AS TotalLeads,
    SUM(p.Amount) AS TotalRevenue,
    ROUND(
        SUM(p.Amount) / NULLIF(c.Budget, 0),
        2
    ) AS ROI
FROM Campaigns c
LEFT JOIN Leads l
    ON c.CampaignID = l.CampaignID
LEFT JOIN Enrollments e
    ON l.LeadID = e.EnrollmentID
LEFT JOIN Payments p
    ON e.EnrollmentID = p.EnrollmentID
GROUP BY
    c.CampaignID,
    c.CampaignName,
    c.Channel,
    c.Budget;

-- PROJECT Q4 — Agent Leaderboard
-- Rankings by leads closed, revenue driven, and conversion rate.
-- Tables: SalesAgents + Leads + Enrollments.
-- Show: AgentName, Region, TotalLeads, ConvertedLeads,
--       TotalRevenue, ConversionRate (%).
SELECT
    a.AgentName,
    a.Region,

    COUNT(DISTINCT l.LeadID) AS TotalLeads,

    COUNT(DISTINCT e.EnrollmentID) AS ConvertedLeads,

    SUM(e.EnrollmentID) AS TotalRevenue,

    CAST(
        COUNT(DISTINCT e.EnrollmentID) * 100.0
        / NULLIF(COUNT(DISTINCT l.LeadID), 0)
        AS DECIMAL(5,1)
    ) AS ConversionRate

FROM SalesAgents a

LEFT JOIN Leads l
    ON a.AgentID = l.AgentID

LEFT JOIN Enrollments e
    ON l.LeadID = e.EnrollmentID

GROUP BY
    a.AgentID,
    a.AgentName,
    a.Region

ORDER BY
    ConversionRate DESC,
    TotalRevenue DESC;


