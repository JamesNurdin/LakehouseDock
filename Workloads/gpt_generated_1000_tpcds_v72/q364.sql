WITH sales_filtered AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        d.d_day_name,
        t.t_meal_time
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(d.d_day_name, '^(Mon|Tue|Wed|Thu|Fri)$')
      AND t.t_meal_time LIKE '%Dinner%'
)
SELECT
    s.s_store_id,
    CONCAT(s.s_city, ', ', s.s_state) AS location,
    REGEXP_EXTRACT(s.s_store_name, '(Market|Store)') AS name_category,
    SUM(sf.ss_net_paid) AS total_net_paid,
    COUNT(*) AS transaction_cnt,
    (
        SELECT AVG(cr.cr_return_amount)
        FROM catalog_returns cr
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE sm.sm_ship_mode_id LIKE 'SM%'
    ) AS avg_return_amount_for_ship_modes
FROM sales_filtered sf
JOIN store s ON sf.ss_store_sk = s.s_store_sk
GROUP BY s.s_store_id, s.s_city, s.s_state, s.s_store_name
HAVING SUM(sf.ss_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
