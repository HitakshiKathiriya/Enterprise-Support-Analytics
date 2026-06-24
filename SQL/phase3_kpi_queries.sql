-- ENTERPRISE SUPPORT ANALYTICS & INCIDENT INTELLIGENCE PLATFORM
-- Phase 3: Business KPI Queries (MySQL)
-- Author: Hitakshi Kathiriya


USE support_analytics;

-- KPI 1: Total Tickets

SELECT 
    COUNT(*) AS total_tickets
FROM tickets;
-- Expected: 100,000


-- KPI 2: Tickets by Status

SELECT 
    status,
    COUNT(*)                                    AS ticket_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) 
          OVER(), 2)                            AS percentage
FROM tickets
GROUP BY status
ORDER BY ticket_count DESC;


-- KPI 3: SLA Compliance %
-- How many tickets were resolved within the agreed SLA hours

SELECT
    ROUND(
        100.0 * SUM(CASE WHEN resolution_hours <= sla_hours THEN 1 ELSE 0 END)
        / COUNT(*),
    2) AS sla_compliance_pct
FROM tickets
WHERE status = 'Closed';




-- KPI 4: SLA Compliance by Priority

SELECT
    priority,
    COUNT(*)                                             AS total_tickets,
    SUM(CASE WHEN resolution_hours <= sla_hours 
             THEN 1 ELSE 0 END)                         AS met_sla,
    SUM(CASE WHEN resolution_hours > sla_hours  
             THEN 1 ELSE 0 END)                         AS breached_sla,
    ROUND(100.0 * SUM(CASE WHEN resolution_hours <= sla_hours 
                           THEN 1 ELSE 0 END)
                / COUNT(*), 2)                          AS compliance_pct
FROM tickets
WHERE status = 'Closed'
GROUP BY priority
ORDER BY FIELD(priority, 'Critical', 'High', 'Medium', 'Low');


-- KPI 5: Average Resolution Time by Priority

SELECT
    priority,
    ROUND(AVG(resolution_hours), 2)  AS avg_resolution_hours,
    MIN(resolution_hours)            AS fastest_hours,
    MAX(resolution_hours)            AS slowest_hours
FROM tickets
WHERE status = 'Closed'
GROUP BY priority
ORDER BY FIELD(priority, 'Critical', 'High', 'Medium', 'Low');

-- KPI 6: Average Customer Satisfaction Score (CSAT)

SELECT
    ROUND(AVG(rating), 2)           AS avg_csat_score,
    COUNT(*)                        AS total_feedback,
    SUM(CASE WHEN rating >= 4 
             THEN 1 ELSE 0 END)     AS satisfied_customers,
    SUM(CASE WHEN rating <= 2 
             THEN 1 ELSE 0 END)     AS dissatisfied_customers
FROM customer_feedback;


-- KPI 7: Tickets by Priority

SELECT
    priority,
    COUNT(*)                                    AS ticket_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) 
          OVER(), 2)                            AS percentage
FROM tickets
GROUP BY priority
ORDER BY FIELD(priority, 'Critical', 'High', 'Medium', 'Low');


-- KPI 8: Open Tickets Older Than 7 Days (Overdue)

SELECT
    COUNT(*)  AS overdue_open_tickets
FROM tickets
WHERE status IN ('Open', 'In Progress')
  AND created_date <= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
