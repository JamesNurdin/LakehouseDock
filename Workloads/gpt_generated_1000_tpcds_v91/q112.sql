WITH filtered_customers AS (
    SELECT c_customer_sk
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
      AND c_birth_month = 5
)
SELECT category, source, avg_metric
FROM (
    SELECT
        sm.sm_type AS category,
        'catalog' AS source,
        AVG(cs.cs_net_profit) AS avg_metric
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN filtered_customers fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
    WHERE sm.sm_carrier = 'UPS'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY sm.sm_type
    HAVING AVG(cs.cs_net_profit) > (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
    )
    UNION ALL
    SELECT
        wp.wp_type AS category,
        'web' AS source,
        AVG(wr.wr_net_loss) AS avg_metric
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
    JOIN filtered_customers fc2 ON wr.wr_refunded_customer_sk = fc2.c_customer_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_max_ad_count >= 2
      AND td2.t_minute IN (1, 13, 18)
    GROUP BY wp.wp_type
    HAVING AVG(wr.wr_net_loss) < (
        SELECT AVG(wr2.wr_net_loss)
        FROM web_returns wr2
    )
) AS combined
ORDER BY category, source
