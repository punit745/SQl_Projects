-- ================================================================
-- FUNNEL ANALYSIS
-- Conversion funnel tracking and analysis
-- ================================================================

USE retail_sales_advanced;

-- Funnel events table
CREATE TABLE IF NOT EXISTS funnel_events (
    event_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    session_id VARCHAR(64),
    customer_id INT,
    event_type VARCHAR(50),
    event_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session (session_id),
    INDEX idx_event_type (event_type),
    INDEX idx_created (created_at)
);

-- Funnel step definitions
CREATE TABLE IF NOT EXISTS funnel_steps (
    step_id INT PRIMARY KEY,
    step_name VARCHAR(50),
    step_order INT UNIQUE
);

INSERT IGNORE INTO funnel_steps VALUES
(1, 'page_view', 1),
(2, 'product_view', 2),
(3, 'add_to_cart', 3),
(4, 'checkout_start', 4),
(5, 'payment_info', 5),
(6, 'purchase', 6);

-- Funnel analysis query
WITH funnel_counts AS (
    SELECT 
        fe.event_type,
        fs.step_order,
        COUNT(DISTINCT fe.session_id) AS sessions
    FROM funnel_events fe
    JOIN funnel_steps fs ON fe.event_type = fs.step_name
    WHERE fe.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY fe.event_type, fs.step_order
)
SELECT 
    f.event_type AS step,
    f.sessions,
    FIRST_VALUE(f.sessions) OVER (ORDER BY f.step_order) AS top_of_funnel,
    ROUND(f.sessions * 100.0 / FIRST_VALUE(f.sessions) OVER (ORDER BY f.step_order), 2) AS conversion_from_top,
    LAG(f.sessions) OVER (ORDER BY f.step_order) AS prev_step,
    ROUND(f.sessions * 100.0 / LAG(f.sessions) OVER (ORDER BY f.step_order), 2) AS step_conversion
FROM funnel_counts f
ORDER BY f.step_order;

-- Drop-off analysis
WITH step_transitions AS (
    SELECT 
        e1.event_type AS current_step,
        e2.event_type AS next_step,
        COUNT(*) AS transition_count
    FROM funnel_events e1
    LEFT JOIN funnel_events e2 ON e1.session_id = e2.session_id 
        AND e2.created_at > e1.created_at
    JOIN funnel_steps fs1 ON e1.event_type = fs1.step_name
    LEFT JOIN funnel_steps fs2 ON e2.event_type = fs2.step_name
    WHERE fs2.step_order IS NULL OR fs2.step_order = fs1.step_order + 1
    GROUP BY e1.event_type, e2.event_type
)
SELECT 
    current_step,
    SUM(IF(next_step IS NULL, transition_count, 0)) AS dropoffs,
    SUM(IF(next_step IS NOT NULL, transition_count, 0)) AS continued,
    ROUND(SUM(IF(next_step IS NULL, transition_count, 0)) * 100.0 / SUM(transition_count), 2) AS dropoff_rate
FROM step_transitions
GROUP BY current_step;

-- Time to conversion
SELECT 
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, first_event, purchase_time)), 2) AS avg_minutes_to_convert,
    ROUND(MIN(TIMESTAMPDIFF(MINUTE, first_event, purchase_time)), 2) AS min_minutes,
    ROUND(MAX(TIMESTAMPDIFF(MINUTE, first_event, purchase_time)), 2) AS max_minutes
FROM (
    SELECT 
        session_id,
        MIN(created_at) AS first_event,
        MAX(IF(event_type = 'purchase', created_at, NULL)) AS purchase_time
    FROM funnel_events
    GROUP BY session_id
    HAVING purchase_time IS NOT NULL
) conversions;
