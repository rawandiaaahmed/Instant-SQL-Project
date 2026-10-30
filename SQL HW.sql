-- HW Q1 (Dates)
-- Show all students who enrolled in the last 6 months.
-- Display: StudentName, EnrollDate, and how many days ago they enrolled (DATEDIFF).
SELECT
    s.StudentName,
    e.EnrollDate,
    DATEDIFF(DAY, e.EnrollDate, GETDATE()) AS DaysAgo
FROM Students s
JOIN Enrollments e
    ON s.StudentID = e.StudentID
WHERE e.EnrollDate >= DATEADD(MONTH, -6, GETDATE())
ORDER BY e.EnrollDate DESC;

-- HW Q2 (Dates)
-- Generate a quarterly revenue summary (Q1–Q4) for 2024.
-- Use DATEPART(QUARTER, ...) to group payments by quarter.
-- Show: PayYear, Quarter, TotalRevenue, TotalPayments.
SELECT
    YEAR(PaymentDate) AS PayYear,
    DATEPART(QUARTER, PaymentDate) AS Quarter,
    SUM(Amount) AS TotalRevenue,
    COUNT(PaymentID) AS TotalPayments
FROM Payments
WHERE PaymentDate >= '2024-01-01'
  AND PaymentDate < '2025-01-01'
GROUP BY
    YEAR(PaymentDate),
    DATEPART(QUARTER, PaymentDate)
ORDER BY
    Quarter;
-- HW Q3 (Subquery)
-- Find courses that have NEVER had an enrollment.
-- Use NOT IN with a subquery on the Enrollments table.
-- Show: CourseID, CourseName, Category, Price.
SELECT
    CourseID,
    CourseName,
    Category,
    Price
FROM Courses
WHERE CourseID NOT IN (
    SELECT CourseID
    FROM Enrollments
);

-- HW Q4 (Subquery)
-- List students whose total payment amount (from Payments via Enrollments)
-- is above the academy's overall average total payment per student.
-- Use a subquery in WHERE or HAVING.
-- Show: StudentName, TotalPaid.

SELECT
    s.StudentName,
    SUM(p.Amount) AS TotalPaid
FROM Students s
JOIN Enrollments e
    ON s.StudentID = e.StudentID
JOIN Payments p
    ON e.EnrollmentID = p.EnrollmentID
GROUP BY
    s.StudentID,
    s.StudentName
HAVING SUM(p.Amount) > (
    SELECT AVG(StudentTotal)
    FROM (
        SELECT
            e2.StudentID,
            SUM(p2.Amount) AS StudentTotal
        FROM Enrollments e2
        JOIN Payments p2
            ON e2.EnrollmentID = p2.EnrollmentID
        GROUP BY e2.StudentID
    ) AS StudentPayments
);
-- HW Q5 (CTE)
-- Write a CTE called TopCourses that finds the 5 courses
-- with the most enrollments.
-- Then join it back to Courses to show the full course details and price.
-- Show: CourseName, Category, Price, DurationHrs, TotalEnrollments.

WITH TopCourses AS (
    SELECT TOP 5
        CourseID,
        COUNT(EnrollmentID) AS TotalEnrollments
    FROM Enrollments
    GROUP BY CourseID
    ORDER BY COUNT(EnrollmentID) DESC
)
SELECT
    c.CourseName,
    c.Category,
    c.Price,
    c.DurationHrs,
    tc.TotalEnrollments
FROM Courses c
JOIN TopCourses tc
    ON c.CourseID = tc.CourseID
ORDER BY
    tc.TotalEnrollments DESC;

-- HW Q6 (View)
-- Create vw_CampaignROI: shows each campaign's
--   CampaignName, Channel, Budget, TotalLeads,
--   CostPerLead (Budget / TotalLeads — handle division by zero).
-- Use a LEFT JOIN between Campaigns and Leads.

CREATE VIEW vw_CampaignROI AS
SELECT
    c.CampaignName,
    c.Channel,
    c.Budget,
    COUNT(l.LeadID) AS TotalLeads,
    CAST(
        c.Budget / NULLIF(COUNT(l.LeadID), 0)
        AS DECIMAL(10,2)
    ) AS CostPerLead
FROM Campaigns c
LEFT JOIN Leads l
    ON c.CampaignID = l.CampaignID
GROUP BY
    c.CampaignID,
    c.CampaignName,
    c.Channel,
    c.Budget;
-- PROJECT Q7 — vw_MonthlyEnrollmentRevenue
-- Monthly enrollments count + revenue from payments.
-- Use YEAR(), MONTH(), FORMAT(), and JOIN Enrollments → Payments.
-- Group by month.
-- Show: EnrollYear, EnrollMonth, MonthLabel, TotalEnrollments, TotalRevenue.
CREATE VIEW vw_MonthlyEnrollmentRevenue AS
SELECT
    YEAR(e.EnrollDate) AS EnrollYear,
    MONTH(e.EnrollDate) AS EnrollMonth,
    FORMAT(e.EnrollDate, 'yyyy-MM') AS MonthLabel,
    COUNT(DISTINCT e.EnrollmentID) AS TotalEnrollments,
    SUM(p.Amount) AS TotalRevenue
FROM Enrollments e
JOIN Payments p
    ON e.EnrollmentID = p.EnrollmentID
GROUP BY
    YEAR(e.EnrollDate),
    MONTH(e.EnrollDate),
    FORMAT(e.EnrollDate, 'yyyy-MM');
-- PROJECT Q8 — vw_AgentLeaderboard
-- Per agent: TotalLeads, ConvertedLeads, ConversionRate%,
--            MonthlyAvgLeads (using DATEDIFF to calculate active months).
-- Use CTEs inside the view before wrapping in CREATE VIEW.

CREATE VIEW vw_AgentLeaderboard AS
WITH AgentStats AS
(
    SELECT
        a.AgentID,
        a.AgentName,
        a.Region,
        COUNT(l.LeadID) AS TotalLeads,
        SUM(
            CASE
                WHEN l.Status = 'Enrolled' THEN 1
                ELSE 0
            END
        ) AS ConvertedLeads,
        MIN(l.CreatedDate) AS FirstLeadDate,
        MAX(l.CreatedDate) AS LastLeadDate
    FROM SalesAgents a
    LEFT JOIN Leads l
        ON a.AgentID = l.AgentID
    GROUP BY
        a.AgentID,
        a.AgentName,
        a.Region
),
AgentMonths AS
(
    SELECT
        AgentID,
        TotalLeads,
        ConvertedLeads,
        AgentName,
        Region,
        DATEDIFF(MONTH, FirstLeadDate, LastLeadDate) + 1
            AS ActiveMonths
    FROM AgentStats
)
SELECT
    AgentName,
    Region,
    TotalLeads,
    ConvertedLeads,
    CAST(
        ConvertedLeads * 100.0
        / NULLIF(TotalLeads, 0)
        AS DECIMAL(5,1)
    ) AS ConversionRate,
    CAST(
        TotalLeads * 1.0
        / NULLIF(ActiveMonths, 0)
        AS DECIMAL(10,2)
    ) AS MonthlyAvgLeads
FROM AgentMonths;


-- PROJECT Q9 — vw_CourseDemand
-- Per course: enrollment count, total revenue, average payment,
--             days since last enrollment (DATEDIFF).
-- Join Courses, Enrollments, Payments.
CREATE VIEW vw_CourseDemand AS
SELECT
    c.CourseName,
    c.Category,
    COUNT(DISTINCT e.EnrollmentID) AS EnrollmentCount,
    SUM(p.Amount) AS TotalRevenue,
    AVG(p.Amount) AS AveragePayment,
    DATEDIFF(DAY, MAX(e.EnrollDate), GETDATE()) AS DaysSinceLastEnrollment
FROM Courses c
LEFT JOIN Enrollments e
    ON c.CourseID = e.CourseID
LEFT JOIN Payments p
    ON e.EnrollmentID = p.EnrollmentID
GROUP BY
    c.CourseID,
    c.CourseName,
    c.Category;
-- HW Q10 (20 pts) — Monthly Cohort Analysis
-- For each enrollment month-year, calculate:
--   • The number of students who enrolled that month
--   • The cumulative total of students enrolled up to that month (running sum)
--   • The percentage of total students enrolled in that month
-- Tables: Enrollments, Students
WITH MonthlyEnrollments AS
(
    SELECT
        YEAR(e.EnrollDate) AS EnrollYear,
        MONTH(e.EnrollDate) AS EnrollMonth,
        FORMAT(e.EnrollDate, 'yyyy-MM') AS MonthLabel,
        COUNT(DISTINCT e.StudentID) AS MonthlyStudents
    FROM Enrollments e
    JOIN Students s
        ON e.StudentID = s.StudentID
    GROUP BY
        YEAR(e.EnrollDate),
        MONTH(e.EnrollDate),
        FORMAT(e.EnrollDate, 'yyyy-MM')
)
SELECT
    EnrollYear,
    EnrollMonth,
    MonthLabel,
    MonthlyStudents,

    SUM(MonthlyStudents) OVER (
        ORDER BY EnrollYear, EnrollMonth
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeStudents,

    CAST(
        MonthlyStudents * 100.0
        / SUM(MonthlyStudents) OVER ()
        AS DECIMAL(5,2)
    ) AS EnrollmentPercentage

FROM MonthlyEnrollments
ORDER BY
    EnrollYear,
    EnrollMonth;
-- HW Q11 (25 pts) — Course Popularity Trend
-- Show each course's monthly enrollment count.
-- Use LAG() to find the previous month's enrollment count.
-- Calculate the month-over-month growth rate (%).
-- Use RANK() to rank courses by their average monthly growth rate.
-- Tables: Enrollments, Courses
WITH MonthlyEnrollments AS
(
    SELECT
        c.CourseID,
        c.CourseName,
        YEAR(e.EnrollDate) AS EnrollYear,
        MONTH(e.EnrollDate) AS EnrollMonth,
        FORMAT(e.EnrollDate, 'yyyy-MM') AS MonthLabel,
        COUNT(e.EnrollmentID) AS MonthlyEnrollments
    FROM Courses c
    JOIN Enrollments e
        ON c.CourseID = e.CourseID
    GROUP BY
        c.CourseID,
        c.CourseName,
        YEAR(e.EnrollDate),
        MONTH(e.EnrollDate),
        FORMAT(e.EnrollDate, 'yyyy-MM')
),
MonthlyGrowth AS
(
    SELECT
        CourseID,
        CourseName,
        EnrollYear,
        EnrollMonth,
        MonthLabel,
        MonthlyEnrollments,

        LAG(MonthlyEnrollments) OVER (
            PARTITION BY CourseID
            ORDER BY EnrollYear, EnrollMonth
        ) AS PreviousMonthEnrollments
    FROM MonthlyEnrollments
),
GrowthCalculation AS
(
    SELECT
        CourseID,
        CourseName,
        EnrollYear,
        EnrollMonth,
        MonthLabel,
        MonthlyEnrollments,
        PreviousMonthEnrollments,

        CAST(
            (MonthlyEnrollments - PreviousMonthEnrollments) * 100.0
            / NULLIF(PreviousMonthEnrollments, 0)
            AS DECIMAL(10,2)
        ) AS MoMGrowthRate
    FROM MonthlyGrowth
),
CourseAverageGrowth AS
(
    SELECT
        CourseID,
        CourseName,
        AVG(MoMGrowthRate) AS AverageMonthlyGrowth
    FROM GrowthCalculation
    WHERE MoMGrowthRate IS NOT NULL
    GROUP BY
        CourseID,
        CourseName
)
SELECT
    g.CourseName,
    g.MonthLabel,
    g.MonthlyEnrollments,
    g.PreviousMonthEnrollments,
    g.MoMGrowthRate,
    CAST(a.AverageMonthlyGrowth AS DECIMAL(10,2)) AS AverageMonthlyGrowth,

    RANK() OVER (
        ORDER BY a.AverageMonthlyGrowth DESC
    ) AS CourseRank

FROM GrowthCalculation g
JOIN CourseAverageGrowth a
    ON g.CourseID = a.CourseID
ORDER BY
    CourseRank,
    g.CourseName,
    g.EnrollYear,
    g.EnrollMonth;
-- HW Q12 (30 pts) — Agent Leaderboard with Comparison
-- Create an agent leaderboard by conversion rate.
-- For each agent, show:
--   • TotalLeads
--   • ConvertedLeads
--   • ConversionRate (%)
--   • Rank (by ConversionRate DESC)
--   • Percentile (PERCENT_RANK)
--   • Top agent's name in their region (FIRST_VALUE)
--   • How far they are from the average conversion rate (difference)
-- Tables: SalesAgents, Leads
WITH AgentStats AS
(
    SELECT
        a.AgentID,
        a.AgentName,
        a.Region,

        COUNT(l.LeadID) AS TotalLeads,

        SUM(
            CASE
                WHEN l.Status = 'Enrolled' THEN 1
                ELSE 0
            END
        ) AS ConvertedLeads

    FROM SalesAgents a
    LEFT JOIN Leads l
        ON a.AgentID = l.AgentID

    GROUP BY
        a.AgentID,
        a.AgentName,
        a.Region
),
AgentRates AS
(
    SELECT
        AgentID,
        AgentName,
        Region,
        TotalLeads,
        ConvertedLeads,

        CAST(
            ConvertedLeads * 100.0
            / NULLIF(TotalLeads, 0)
            AS DECIMAL(5,2)
        ) AS ConversionRate

    FROM AgentStats
)
SELECT
    AgentName,
    Region,
    TotalLeads,
    ConvertedLeads,
    ConversionRate,

    RANK() OVER (
        ORDER BY ConversionRate DESC
    ) AS Rank,

    PERCENT_RANK() OVER (
        ORDER BY ConversionRate
    ) AS Percentile,

    FIRST_VALUE(AgentName) OVER (
        PARTITION BY Region
        ORDER BY ConversionRate DESC
    ) AS TopAgentInRegion,

    CAST(
        ConversionRate
        - AVG(ConversionRate) OVER ()
        AS DECIMAL(10,2)
    ) AS DifferenceFromAverage

FROM AgentRates
ORDER BY
    Rank;

-- HW Q13 (25 pts) — Student Progress Dashboard
-- For each student with at least 2 enrollments, show:
--   • All their enrollments sorted by EnrollDate
--   • CourseName
--   • Payment amount for that enrollment
--   • Running total of what they have paid so far
--   • The previous payment amount using LAG()
--   • Their overall payment rank (across all students)
-- Tables: All 8 tables

WITH StudentPayments AS
(
    SELECT
        s.StudentID,
        s.StudentName,
        e.EnrollmentID,
        e.EnrollDate,
        c.CourseName,
        p.Amount AS PaymentAmount,

        COUNT(e.EnrollmentID) OVER (
            PARTITION BY s.StudentID
        ) AS EnrollmentCount

    FROM Students s
    JOIN Enrollments e
        ON s.StudentID = e.StudentID

    JOIN Courses c
        ON e.CourseID = c.CourseID

    JOIN Payments p
        ON e.EnrollmentID = p.EnrollmentID
),
QualifiedStudents AS
(
    SELECT *
    FROM StudentPayments
    WHERE EnrollmentCount >= 2
),
StudentProgress AS
(
    SELECT
        StudentID,
        StudentName,
        EnrollmentID,
        EnrollDate,
        CourseName,
        PaymentAmount,

        SUM(PaymentAmount) OVER (
            PARTITION BY StudentID
            ORDER BY EnrollDate, EnrollmentID
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS RunningTotalPaid,

        LAG(PaymentAmount) OVER (
            PARTITION BY StudentID
            ORDER BY EnrollDate, EnrollmentID
        ) AS PreviousPayment,

        SUM(PaymentAmount) OVER (
            PARTITION BY StudentID
        ) AS OverallStudentPaid

    FROM QualifiedStudents
)
SELECT
    StudentName,
    EnrollDate,
    CourseName,
    PaymentAmount,
    RunningTotalPaid,
    PreviousPayment,

    RANK() OVER (
        ORDER BY OverallStudentPaid DESC
    ) AS OverallPaymentRank

FROM StudentProgress
ORDER BY
    StudentName,
    EnrollDate;
-- PROJECT Q14 (A — 20 pts) — Leaderboard Query
-- Create a query that shows the top 5 students by total payments per city.
-- Use RANK() partitioned by City.
-- Show: StudentName, City, TotalPaid, CityRank.
WITH StudentPayments AS
(
    SELECT
        s.StudentID,
        s.StudentName,
        s.City,
        SUM(p.Amount) AS TotalPaid
    FROM Students s
    JOIN Enrollments e
        ON s.StudentID = e.StudentID
    JOIN Payments p
        ON e.EnrollmentID = p.EnrollmentID
    GROUP BY
        s.StudentID,
        s.StudentName,
        s.City
),
RankedStudents AS
(
    SELECT
        StudentName,
        City,
        TotalPaid,
        RANK() OVER (
            PARTITION BY City
            ORDER BY TotalPaid DESC
        ) AS CityRank
    FROM StudentPayments
)
SELECT
    StudentName,
    City,
    TotalPaid,
    CityRank
FROM RankedStudents
WHERE CityRank <= 5
ORDER BY
    City,
    CityRank;
-- PROJECT Q15 (B — 25 pts) — Monthly Growth Report
-- Build a monthly enrollment report showing:
--   • This month's enrollment count
--   • Last month's count (LAG)
--   • Next month's count (LEAD)
--   • A trend label: 'Up' / 'Down' / 'Stable' using CASE
WITH MonthlyEnrollments AS
(
    SELECT
        YEAR(EnrollDate) AS EnrollYear,
        MONTH(EnrollDate) AS EnrollMonth,
        FORMAT(EnrollDate, 'yyyy-MM') AS MonthLabel,
        COUNT(*) AS ThisMonthCount
    FROM Enrollments
    GROUP BY
        YEAR(EnrollDate),
        MONTH(EnrollDate),
        FORMAT(EnrollDate, 'yyyy-MM')
),
MonthlyComparison AS
(
    SELECT
        EnrollYear,
        EnrollMonth,
        MonthLabel,
        ThisMonthCount,

        LAG(ThisMonthCount) OVER (
            ORDER BY EnrollYear, EnrollMonth
        ) AS LastMonthCount,

        LEAD(ThisMonthCount) OVER (
            ORDER BY EnrollYear, EnrollMonth
        ) AS NextMonthCount

    FROM MonthlyEnrollments
)
SELECT
    MonthLabel,
    ThisMonthCount,
    LastMonthCount,
    NextMonthCount,

    CASE
        WHEN LastMonthCount IS NULL THEN 'Stable'
        WHEN ThisMonthCount > LastMonthCount THEN 'Up'
        WHEN ThisMonthCount < LastMonthCount THEN 'Down'
        ELSE 'Stable'
    END AS Trend

FROM MonthlyComparison
ORDER BY
    EnrollYear,
    EnrollMonth;
-- PROJECT Q16 (C — 25 pts) — Campaign Efficiency Ranking
-- Rank all campaigns by ROI (Revenue / Budget).
-- Add a running total of cumulative revenue by campaign start date.
-- Add a column showing which channel performs best overall using FIRST_VALUE.
WITH CampaignStats AS
(
    SELECT
        c.CampaignID,
        c.CampaignName,
        c.Channel,
        c.Budget,
        

        COALESCE(SUM(p.Amount), 0) AS TotalRevenue

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
        c.Budget,
        
),
CampaignROI AS
(
    SELECT
        CampaignID,
        CampaignName,
        Channel,
        Budget,
        
        TotalRevenue,

        CAST(
            TotalRevenue * 1.0
            / NULLIF(Budget, 0)
            AS DECIMAL(10,2)
        ) AS ROI

    FROM CampaignStats
)
SELECT
    CampaignName,
    Channel,
    Budget,
    TotalRevenue,
    ROI,

    RANK() OVER (
        ORDER BY ROI DESC
    ) AS ROIRank,

    SUM(TotalRevenue) OVER (
        ORDER BY StartDate, CampaignID
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS CumulativeRevenue,

    FIRST_VALUE(Channel) OVER (
        ORDER BY ROI DESC
    ) AS BestChannelOverall

FROM CampaignROI
ORDER BY
    ROIRank;
-- PROJECT Q17 (D — 30 pts) — Full Dashboard Query
-- Combine data from all 8 tables into one result set.
-- Include: CourseName, TotalEnrollments, TotalPayments, AttendanceRate,
--          LeadCount, RevenueRank, EnrollmentRank.
-- Ready for Power BI connection.

WITH CourseEnrollments AS
(
    SELECT
        c.CourseID,
        c.CourseName,
        COUNT(DISTINCT e.EnrollmentID) AS TotalEnrollments
    FROM Courses c
    LEFT JOIN Enrollments e
        ON c.CourseID = e.CourseID
    GROUP BY
        c.CourseID,
        c.CourseName
),
CoursePayments AS
(
    SELECT
        c.CourseID,
        COUNT(DISTINCT p.PaymentID) AS TotalPayments,
        COALESCE(SUM(p.Amount), 0) AS TotalRevenue
    FROM Courses c
    LEFT JOIN Enrollments e
        ON c.CourseID = e.CourseID
    LEFT JOIN Payments p
        ON e.EnrollmentID = p.EnrollmentID
    GROUP BY
        c.CourseID
),
CourseAttendance AS
(
    SELECT
        c.CourseID,

        COUNT(a.AttendenceID) AS TotalAttendanceSessions,

        SUM(
            CASE
                WHEN a.AttendStatus = 'Attended' THEN 1
                ELSE 0
            END
        ) AS AttendedSessions

    FROM Courses c
    LEFT JOIN Enrollments e
        ON c.CourseID = e.CourseID
    LEFT JOIN Attendence a
        ON e.EnrollmentID = a.EnrollmentID
    GROUP BY
        c.CourseID
),
CourseLeads AS
(
    SELECT
        c.CourseID,
        COUNT(DISTINCT l.LeadID) AS LeadCount

    FROM Courses c
    LEFT JOIN Enrollments e
        ON c.CourseID = e.CourseID
    LEFT JOIN Leads l
        ON e.LeadID = l.LeadID
    GROUP BY
        c.CourseID
),
CourseDashboard AS
(
    SELECT
        c.CourseID,
        c.CourseName,

        ce.TotalEnrollments,
        cp.TotalPayments,

        CAST(
            ca.AttendedSessions * 100.0
            / NULLIF(ca.TotalAttendanceSessions, 0)
            AS DECIMAL(5,2)
        ) AS AttendanceRate,

        cl.LeadCount,
        cp.TotalRevenue

    FROM Courses c

    LEFT JOIN CourseEnrollments ce
        ON c.CourseID = ce.CourseID

    LEFT JOIN CoursePayments cp
        ON c.CourseID = cp.CourseID

    LEFT JOIN CourseAttendance ca
        ON c.CourseID = ca.CourseID

    LEFT JOIN CourseLeads cl
        ON c.CourseID = cl.CourseID
)
SELECT
    CourseName,
    TotalEnrollments,
    TotalPayments,
    AttendanceRate,
    LeadCount,

    RANK() OVER (
        ORDER BY TotalRevenue DESC
    ) AS RevenueRank,

    RANK() OVER (
        ORDER BY TotalEnrollments DESC
    ) AS EnrollmentRank

FROM CourseDashboard
ORDER BY
    EnrollmentRank,
    RevenueRank;