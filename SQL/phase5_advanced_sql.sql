-- ENTERPRISE SUPPORT ANALYTICS & INCIDENT INTELLIGENCE PLATFORM
-- Phase 5: Advanced SQL — Window Functions, CTEs, Stored Procedures
-- Author: Hitakshi Kathiriya

USE support_analytics;


-- ADVANCED 1: Rank Engineers by Tickets Resolved
-- Window Function: RANK()

SELECT
    e.engineer_name,
    e.team,
    COUNT(t.ticket_id)                              AS tickets_resolved,
    ROUND(AVG(t.resolution_hours), 1)               AS avg_resolution_hrs,
    RANK() OVER (ORDER BY COUNT(t.ticket_id) DESC)  AS overall_rank,
    RANK() OVER (PARTITION BY e.team 
                 ORDER BY COUNT(t.ticket_id) DESC)  AS rank_within_team
FROM tickets t
JOIN support_engineers e ON t.engineer_id = e.engineer_id
WHERE t.status = 'Closed'
GROUP BY e.engineer_name, e.team
ORDER BY overall_rank;


-- ADVANCED 2: Monthly Ticket Trend
-- Window Function: LAG() for Month-over-Month Growth

WITH monthly_summary AS (
    SELECT
        DATE_FORMAT(created_date, '%Y-%m')          AS month,
        COUNT(*)                                    AS total_tickets,
        SUM(CASE WHEN priority = 'Critical' 
                 THEN 1 ELSE 0 END)                 AS critical_tickets,
        SUM(CASE WHEN status = 'Closed' 
                 THEN 1 ELSE 0 END)                 AS resolved_tickets
    FROM tickets
    GROUP BY DATE_FORMAT(created_date, '%Y-%m')
)
SELECT
    month,
    total_tickets,
    critical_tickets,
    resolved_tickets,
    LAG(total_tickets) OVER (ORDER BY month)        AS prev_month_tickets,
    ROUND(
        100.0 * (total_tickets - LAG(total_tickets) OVER (ORDER BY month))
              / LAG(total_tickets) OVER (ORDER BY month),
    2)                                              AS mom_growth_pct
FROM monthly_summary
ORDER BY month;


-- ADVANCED 3: Running Total of Tickets Per Month
-- Window Function: SUM() cumulative

WITH monthly_counts AS (
    SELECT
        DATE_FORMAT(created_date, '%Y-%m')          AS month,
        COUNT(*)                                    AS tickets_this_month
    FROM tickets
    GROUP BY DATE_FORMAT(created_date, '%Y-%m')
)
SELECT
    month,
    tickets_this_month,
    SUM(tickets_this_month) OVER (ORDER BY month)  AS running_total
FROM monthly_counts
ORDER BY month;


-- ADVANCED 4: Top 3 Engineers Per Team
-- Window Function: DENSE_RANK() with PARTITION

WITH engineer_stats AS (
    SELECT
        e.engineer_name,
        e.team,
        COUNT(t.ticket_id)                          AS tickets_resolved,
        ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
        DENSE_RANK() OVER (
            PARTITION BY e.team
            ORDER BY COUNT(t.ticket_id) DESC
        )                                           AS team_rank
    FROM tickets t
    JOIN support_engineers e ON t.engineer_id = e.engineer_id
    WHERE t.status = 'Closed'
    GROUP BY e.engineer_name, e.team
)
SELECT * FROM engineer_stats
WHERE team_rank <= 3
ORDER BY team, team_rank;


-- ADVANCED 5: SLA Breach Detection with Root Cause
-- CTE + Aggregation

WITH sla_breaches AS (
    SELECT
        t.ticket_id,
        t.priority,
        t.root_cause,
        t.sla_hours,
        t.resolution_hours,
        (t.resolution_hours - t.sla_hours)          AS hours_over_sla,
        c.customer_name,
        p.product_name
    FROM tickets t
    JOIN customers c ON t.customer_id = c.customer_id
    JOIN products p  ON t.product_id  = p.product_id
    WHERE t.status = 'Closed'
      AND t.resolution_hours > t.sla_hours
)
SELECT
    root_cause,
    priority,
    COUNT(*)                                        AS breach_count,
    ROUND(AVG(hours_over_sla), 1)                   AS avg_hours_over_sla,
    MAX(hours_over_sla)                             AS worst_breach_hrs
FROM sla_breaches
GROUP BY root_cause, priority
ORDER BY breach_count DESC
LIMIT 15;


-- ADVANCED 6: Customer Health Score
-- CTE combining SLA breaches + CSAT + open tickets

WITH ticket_stats AS (
    SELECT
        t.customer_id,
        COUNT(*)                                    AS total_tickets,
        SUM(CASE WHEN t.status IN ('Open','In Progress') 
                 THEN 1 ELSE 0 END)                 AS open_tickets,
        ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= t.sla_hours 
                               THEN 1 ELSE 0 END)
                    / COUNT(*), 2)                  AS sla_compliance_pct
    FROM tickets t
    GROUP BY t.customer_id
),
csat_stats AS (
    SELECT
        t.customer_id,
        ROUND(AVG(f.rating), 2)                     AS avg_csat
    FROM customer_feedback f
    JOIN tickets t ON f.ticket_id = t.ticket_id
    GROUP BY t.customer_id
)
SELECT
    c.customer_name,
    c.subscription_plan,
    ts.total_tickets,
    ts.open_tickets,
    ts.sla_compliance_pct,
    cs.avg_csat,
    CASE
        WHEN cs.avg_csat >= 4 AND ts.sla_compliance_pct >= 70 THEN 'Healthy'
        WHEN cs.avg_csat >= 3 AND ts.sla_compliance_pct >= 50 THEN 'At Risk'
        ELSE 'Critical Account'
    END                                             AS account_health
FROM ticket_stats ts
JOIN csat_stats cs  ON ts.customer_id  = cs.customer_id
JOIN customers c    ON ts.customer_id  = c.customer_id
ORDER BY avg_csat ASC
LIMIT 20;

-- ============================================================
-- ADVANCED 7: Stored Procedure — SLA Report by Priority
-- Call: CALL GetSLAReport('Critical');
-- ============================================================
DELIMITER $$

CREATE PROCEDURE GetSLAReport(IN p_priority VARCHAR(20))
BEGIN
    SELECT
        p_priority                                  AS priority_filter,
        COUNT(*)                                    AS total_tickets,
        SUM(CASE WHEN resolution_hours <= sla_hours 
                 THEN 1 ELSE 0 END)                 AS met_sla,
        SUM(CASE WHEN resolution_hours > sla_hours  
                 THEN 1 ELSE 0 END)                 AS breached_sla,
        ROUND(100.0 * SUM(CASE WHEN resolution_hours <= sla_hours 
                               THEN 1 ELSE 0 END)
                    / COUNT(*), 2)                  AS compliance_pct,
        ROUND(AVG(resolution_hours), 1)             AS avg_resolution_hrs
    FROM tickets
    WHERE status   = 'Closed'
      AND priority = p_priority;
END$$

DELIMITER ;

-- Test the stored procedure
CALL GetSLAReport('Critical');
CALL GetSLAReport('High');
CALL GetSLAReport('Medium');
CALL GetSLAReport('Low');


-- ADVANCED 8: Stored Procedure — Engineer Performance Report
-- Call: CALL GetEngineerReport('Tier-1 Support');

DELIMITER $$

CREATE PROCEDURE GetEngineerReport(IN p_team VARCHAR(50))
BEGIN
    SELECT
        e.engineer_name,
        e.team,
        COUNT(t.ticket_id)                          AS tickets_resolved,
        ROUND(AVG(t.resolution_hours), 1)           AS avg_resolution_hrs,
        ROUND(100.0 * SUM(CASE WHEN t.resolution_hours <= t.sla_hours 
                               THEN 1 ELSE 0 END)
                    / COUNT(*), 2)                  AS sla_compliance_pct,
        ROUND(AVG(f.rating), 2)                     AS avg_csat
    FROM tickets t
    JOIN support_engineers e ON t.engineer_id  = e.engineer_id
    LEFT JOIN customer_feedback f ON t.ticket_id = f.ticket_id
    WHERE t.status   = 'Closed'
      AND e.team     = p_team
    GROUP BY e.engineer_name, e.team
    ORDER BY tickets_resolved DESC;
END$$

DELIMITER ;

-- Test the stored procedure
CALL GetEngineerReport('Tier-1 Support');
CALL GetEngineerReport('Cloud Ops');
