WITH sales_agg AS (
    SELECT
        p.p_promo_name,
        sm.sm_type,
        sm.sm_code,
        t.t_meal_time,
        t.t_am_pm,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) DESC) AS rn
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_discount_active = 'Y'
      AND sm.sm_type IN ('EXPRESS', 'NEXT DAY')
      AND t.t_meal_time = 'lunch'
      AND t.t_am_pm = 'PM'
      AND p.p_promo_name LIKE '%Clearance%'
    GROUP BY p.p_promo_name, sm.sm_type, sm.sm_code, t.t_meal_time, t.t_am_pm
)
SELECT
    p_promo_name,
    sm_type,
    sm_code,
    t_meal_time,
    t_am_pm,
    store_sales_amount,
    web_sales_amount,
    (store_sales_amount + web_sales_amount) AS total_sales,
    store_txn_cnt,
    web_txn_cnt,
    DENSE_RANK() OVER (ORDER BY (store_sales_amount + web_sales_amount) DESC) AS sales_rank
FROM sales_agg
WHERE rn = 1
ORDER BY total_sales DESC
LIMIT 100
