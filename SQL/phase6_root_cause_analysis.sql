
-- ENTERPRISE SUPPORT ANALYTICS & INCIDENT INTELLIGENCE PLATFORM
-- Phase 6: Root Cause Analysis & Incident Intelligence
-- Author: Hitakshi Kathiriya


USE support_analytics;

=
-- RCA 1: Most Common Root Causes Overall

SELECT
    root_cause,
    COUNT(*)                                        AS total_incidents,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) 
          OVER(), 2)                                AS pct_of_total,
    ROUND(AVG(resolution_hours), 1)                 AS avg_resolution_hrs,
    SUM(CASE WHEN priority = 'Critical' 
             THEN 1 ELSE 0 END)                     AS critical_count
FROM tickets
GROUP BY root_cause
ORDER BY total_incidents DESC;


-- RCA 2: Root Cause by Priority
-- Which root causes drive the most critical tickets?

SELECT
    root_cause,
    SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END) AS critical,
    SUM(CASE WHEN priority = 'High'     THEN 1 ELSE 0 END) AS high,
    SUM(CASE WHEN priority = 'Medium'   THEN 1 ELSE 0 END) AS medium,
    SUM(CASE WHEN priority = 'Low'      THEN 1 ELSE 0 END) AS low,
    COUNT(*)                                                AS total
FROM tickets
GROUP BY root_cause
ORDER BY critical DESC;


-- RCA 3: Root Causes That Breach SLA Most
-- The most dangerous failure types

WITH rca_sla AS (
    SELECT
        root_cause,
        COUNT(*)                                    AS total_tickets,
        SUM(CASE WHEN resolution_hours > sla_hours 
                 THEN 1 ELSE 0 END)                 AS sla_breaches,
        ROUND(AVG(resolution_hours), 1)             AS avg_resolution_hrs
    FROM tickets
    WHERE status = 'Closed'
    GROUP BY root_cause
)
SELECT
    root_cause,
    total_tickets,
    sla_breaches,
    ROUND(100.0 * sla_breaches / total_tickets, 2)  AS breach_rate_pct,
    avg_resolution_hrs
FROM rca_sla
ORDER BY breach_rate_pct DESC;


-- RCA 4: Root Cause Trend Over Time
-- Are certain failures increasing month over month?

SELECT
    DATE_FORMAT(created_date, '%Y-%m')              AS month,
    root_cause,
    COUNT(*)                                        AS incident_count
FROM tickets
GROUP BY DATE_FORMAT(created_date, '%Y-%m'), root_cause
ORDER BY month, incident_count DESC;


-- RCA 5: Product + Root Cause Matrix
-- Which products fail for which reasons?

SELECT
    p.product_name,
    t.root_cause,
    COUNT(*)                                        AS incident_count,
    ROUND(AVG(t.resolution_hours), 1)               AS avg_resolution_hrs,
    ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= t.sla_hours 
                           THEN 1 ELSE 0 END)
                / COUNT(*), 2)                      AS sla_compliance_pct
FROM tickets t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.product_name, t.root_cause
ORDER BY p.product_name, incident_count DESC;


-- RCA 6: Recurring Incidents — Same Customer, Same Root Cause
-- Identifies systemic problems not being permanently fixed

SELECT
    c.customer_name,
    t.root_cause,
    COUNT(*)                                        AS recurrence_count,
    MIN(t.created_date)                             AS first_occurrence,
    MAX(t.created_date)                             AS latest_occurrence,
    DATEDIFF(MAX(t.created_date), 
             MIN(t.created_date))                   AS days_span
FROM tickets t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.customer_name, t.root_cause
HAVING recurrence_count >= 5
ORDER BY recurrence_count DESC
LIMIT 20;


-- RCA 7: Root Cause Impact on CSAT
-- Do certain failure types damage customer satisfaction more?

SELECT
    t.root_cause,
    COUNT(f.feedback_id)                            AS feedback_count,
    ROUND(AVG(f.rating), 2)                         AS avg_csat,
    SUM(CASE WHEN f.rating <= 2 
             THEN 1 ELSE 0 END)                     AS dissatisfied_count,
    ROUND(100.0 * SUM(CASE WHEN f.rating <= 2 
                           THEN 1 ELSE 0 END)
                / COUNT(*), 2)                      AS dissatisfaction_rate_pct
FROM tickets t
JOIN customer_feedback f ON t.ticket_id = f.ticket_id
GROUP BY t.root_cause
ORDER BY avg_csat ASC;


-- RCA 8: Executive Incident Summary
-- One query that tells the full story

WITH incident_summary AS (
    SELECT
        t.root_cause,
        COUNT(*)                                    AS total_incidents,
        SUM(CASE WHEN t.priority = 'Critical' 
                 THEN 1 ELSE 0 END)                 AS critical_count,
        ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
        SUM(CASE WHEN t.resolution_hours > t.sla_hours 
                 THEN 1 ELSE 0 END)                 AS sla_breaches
    FROM tickets t
    WHERE t.status = 'Closed'
    GROUP BY t.root_cause
),
csat_summary AS (
    SELECT
        t.root_cause,
        ROUND(AVG(f.rating), 2)                     AS avg_csat
    FROM tickets t
    JOIN customer_feedback f ON t.ticket_id = f.ticket_id
    GROUP BY t.root_cause
)
SELECT
    i.root_cause,
    i.total_incidents,
    i.critical_count,
    i.avg_resolution_hrs,
    i.sla_breaches,
    ROUND(100.0 * i.sla_breaches / i.total_incidents, 1) AS breach_rate_pct,
    c.avg_csat,
    CASE
        WHEN i.critical_count > 500 
          AND c.avg_csat < 3.5     THEN 'IMMEDIATE ACTION'
        WHEN i.critical_count > 300 
          OR  c.avg_csat < 3.8     THEN 'MONITOR CLOSELY'
        ELSE                            'STABLE'
    END                                             AS action_required
FROM incident_summary i
JOIN csat_summary c ON i.root_cause = c.root_cause
ORDER BY i.critical_count DESC;
