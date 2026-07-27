/*
Goal: Compare high‑profit stores with active customers by aggregating store net profit and web page view counts, categorizing each entity, filtering out low‑performing groups, and returning the top entities.
*/
WITH store_agg AS (
    SELECT
        'Store' AS entity_type,
        s.s_store_id AS entity_id,
        'TotalProfit' AS metric_name,
        SUM(ss.ss_net_profit) AS metric_value,
        CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE s.s_rec_start_date >= DATE '2000-01-01'
      AND s.s_rec_start_date < DATE '2001-01-01'
    GROUP BY s.s_store_id
    HAVING SUM(ss.ss_net_profit) > 500
),
customer_agg AS (
    SELECT
        'Customer' AS entity_type,
        c.c_customer_id AS entity_id,
        'PageViews' AS metric_name,
        COUNT(wp.wp_web_page_sk) AS metric_value,
        CASE WHEN COUNT(wp.wp_web_page_sk) > 10 THEN 'Heavy' ELSE 'Light' END AS category
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_access_date_sk IN (2452565, 2452639, 2452580)
    GROUP BY c.c_customer_id
    HAVING COUNT(wp.wp_web_page_sk) >= 5
)
SELECT
    entity_type,
    entity_id,
    metric_name,
    metric_value,
    category
FROM store_agg
UNION ALL
SELECT
    entity_type,
    entity_id,
    metric_name,
    metric_value,
    category
FROM customer_agg
ORDER BY metric_value DESC
LIMIT 100
