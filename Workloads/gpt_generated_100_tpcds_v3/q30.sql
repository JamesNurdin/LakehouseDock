WITH
customer_hhd AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_first_shipto_date_sk,
        c.c_last_review_date,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_buy_potential
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
      AND c.c_first_shipto_date_sk BETWEEN 2450000 AND 2453000
      AND c.c_last_review_date < 2452500
),
store_agg AS (
    SELECT
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM tpcds.store_sales ss
    GROUP BY ss.ss_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS ws_customer_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ws.ws_ext_discount_amt) AS total_web_discount,
        COUNT(*) AS web_order_cnt
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_list_price > 1000
      AND ws.ws_warehouse_sk IN (9, 12)
    GROUP BY ws.ws_bill_customer_sk, ws.ws_ship_mode_sk
),
ship_mode_agg AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        (SELECT AVG(ws2.ws_ext_discount_amt)
         FROM tpcds.web_sales ws2
         WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk) AS avg_discount_by_ship
    FROM tpcds.ship_mode sm
)
SELECT
    ch.c_customer_id,
    ch.c_first_name,
    ch.c_last_name,
    ch.hd_buy_potential,
    ch.hd_vehicle_count,
    COALESCE(sa.total_store_sales, 0) AS total_store_sales,
    COALESCE(wa.total_web_sales, 0) AS total_web_sales,
    COALESCE(sa.total_store_sales, 0) + COALESCE(wa.total_web_sales, 0) AS total_combined_sales,
    CASE
        WHEN COALESCE(sa.total_store_sales, 0) + COALESCE(wa.total_web_sales, 0) > 10000 THEN 'High'
        WHEN COALESCE(sa.total_store_sales, 0) + COALESCE(wa.total_web_sales, 0) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    sm.avg_discount_by_ship,
    RANK() OVER (ORDER BY (COALESCE(sa.total_store_sales, 0) + COALESCE(wa.total_web_sales, 0)) DESC) AS sales_rank
FROM customer_hhd ch
LEFT JOIN store_agg sa
    ON sa.ss_customer_sk = ch.c_customer_sk
LEFT JOIN web_agg wa
    ON wa.ws_customer_sk = ch.c_customer_sk
LEFT JOIN ship_mode_agg sm
    ON wa.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY sales_rank
LIMIT 100
