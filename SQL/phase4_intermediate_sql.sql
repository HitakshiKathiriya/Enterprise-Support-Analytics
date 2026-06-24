-- ENTERPRISE SUPPORT ANALYTICS & INCIDENT INTELLIGENCE PLATFORM
-- Phase 4: Intermediate SQL — JOINs & Business Insights
-- Author: Hitakshi Kathiriya

USE support_analytics;


-- QUERY 1: Top 10 Customers Generating Most Tickets

SELECT
    c.customer_name,
    c.industry,
    c.subscription_plan,
    COUNT(t.ticket_id)                          AS total_tickets,
    SUM(CASE WHEN t.status = 'Open' 
             THEN 1 ELSE 0 END)                 AS open_tickets,
    ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs
FROM tickets t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.customer_name, c.industry, c.subscription_plan
ORDER BY total_tickets DESC
LIMIT 10;


-- QUERY 2: Most Problematic Products (Most Tickets)

SELECT
    p.product_name,
    p.release_version,
    COUNT(t.ticket_id)                          AS total_issues,
    SUM(CASE WHEN t.priority = 'Critical' 
             THEN 1 ELSE 0 END)                 AS critical_issues,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= t.sla_hours 
                           THEN 1 ELSE 0 END)
                / COUNT(t.ticket_id), 2)        AS sla_compliance_pct
FROM tickets t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.product_name, p.release_version
ORDER BY total_issues DESC;


-- QUERY 3: Ticket Volume by Industry
-- Which industries raise the most support tickets?

SELECT
    c.industry,
    COUNT(t.ticket_id)                          AS total_tickets,
    ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
    ROUND(AVG(f.rating), 2)                     AS avg_csat
FROM tickets t
JOIN customers c  ON t.customer_id  = c.customer_id
LEFT JOIN customer_feedback f ON t.ticket_id = f.ticket_id
GROUP BY c.industry
ORDER BY total_tickets DESC;


-- QUERY 4: Ticket Volume by Subscription Plan
-- Do premium customers get better/faster support?

SELECT
    c.subscription_plan,
    COUNT(t.ticket_id)                          AS total_tickets,
    ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= t.sla_hours 
                           THEN 1 ELSE 0 END)
                / COUNT(t.ticket_id), 2)        AS sla_compliance_pct,
    ROUND(AVG(f.rating), 2)                     AS avg_csat
FROM tickets t
JOIN customers c ON t.customer_id = c.customer_id
LEFT JOIN customer_feedback f ON t.ticket_id = f.ticket_id
WHERE t.status = 'Closed'
GROUP BY c.subscription_plan
ORDER BY avg_resolution_hrs ASC;


-- QUERY 5: Engineer Performance Summary
-- Who resolves the most tickets?

SELECT
    e.engineer_name,
    e.team,
    COUNT(t.ticket_id)                          AS tickets_resolved,
    ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= t.sla_hours 
                           THEN 1 ELSE 0 END)
                / COUNT(t.ticket_id), 2)        AS sla_compliance_pct,
    ROUND(AVG(f.rating), 2)                     AS avg_csat
FROM tickets t
JOIN support_engineers e ON t.engineer_id  = e.engineer_id
LEFT JOIN customer_feedback f ON t.ticket_id = f.ticket_id
WHERE t.status = 'Closed'
GROUP BY e.engineer_name, e.team
ORDER BY tickets_resolved DESC
LIMIT 15;


-- QUERY 6: Team Performance Comparison
-- Which support team performs best?

SELECT
    e.team,
    COUNT(t.ticket_id)                          AS total_tickets,
    ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= t.sla_hours 
                           THEN 1 ELSE 0 END)
                / COUNT(t.ticket_id), 2)        AS sla_compliance_pct,
    ROUND(AVG(f.rating), 2)                     AS avg_csat
FROM tickets t
JOIN support_engineers e ON t.engineer_id  = e.engineer_id
LEFT JOIN customer_feedback f ON t.ticket_id = f.ticket_id
WHERE t.status = 'Closed'
GROUP BY e.team
ORDER BY sla_compliance_pct DESC;


-- QUERY 7: Customers With Low CSAT (At-Risk Accounts)
-- These are clients who might churn

SELECT
    c.customer_name,
    c.industry,
    c.subscription_plan,
    COUNT(f.feedback_id)                        AS feedback_count,
    ROUND(AVG(f.rating), 2)                     AS avg_csat,
    SUM(CASE WHEN f.rating <= 2 
             THEN 1 ELSE 0 END)                 AS bad_ratings
FROM customer_feedback f
JOIN tickets t     ON f.ticket_id   = t.ticket_id
JOIN customers c   ON t.customer_id = c.customer_id
GROUP BY c.customer_name, c.industry, c.subscription_plan
HAVING avg_csat < 3.0
ORDER BY avg_csat ASC
LIMIT 10;


-- QUERY 8: Country-wise Ticket Distribution

SELECT
    c.country,
    COUNT(t.ticket_id)                          AS total_tickets,
    ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
    ROUND(AVG(f.rating), 2)                     AS avg_csat
FROM tickets t
JOIN customers c ON t.customer_id = c.customer_id
LEFT JOIN customer_feedback f ON t.ticket_id = f.ticket_id
GROUP BY c.country
ORDER BY total_tickets DESC;
