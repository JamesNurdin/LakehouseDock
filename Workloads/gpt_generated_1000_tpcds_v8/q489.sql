WITH
    cc_sample AS (
        SELECT *
        FROM call_center TABLESAMPLE BERNOULLI (10)
    ),
    intersect_stores AS (
        SELECT sr.sr_store_sk AS store_sk
        FROM store_returns sr
        INTERSECT
        SELECT s.s_store_sk
        FROM store s
    ),
    except_stores AS (
        SELECT s.s_store_sk AS store_sk
        FROM store s
        EXCEPT
        SELECT sr.sr_store_sk
        FROM store_returns sr
    )
SELECT
    s.s_store_name,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    wp.wp_type AS web_page_type,
    t.t_hour AS hour_of_day,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    SUM(CASE WHEN cs.cs_ext_sales_price > 1000 THEN cs.cs_ext_sales_price ELSE 0 END) AS high_value_sales,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'Top Store'
        ELSE 'Regular Store'
    END AS store_category
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN cc_sample cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
LEFT JOIN ship_mode sm_left
    ON cs.cs_ship_mode_sk = sm_left.sm_ship_mode_sk
JOIN intersect_stores i
    ON s.s_store_sk = i.store_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM except_stores e
    WHERE e.store_sk = s.s_store_sk
)
GROUP BY
    s.s_store_name,
    cc.cc_name,
    sm.sm_type,
    wp.wp_type,
    t.t_hour
ORDER BY total_sales DESC
LIMIT 100
