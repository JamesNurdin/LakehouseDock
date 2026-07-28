/*
Goal: Calculate total return amount and total web sales amount by store, shipping carrier, and warehouse city for customers in California who have at least three employed dependents. The query filters to high‑value web sales (list price > 50) and returns with significant tax (> 10). It joins all seven selected TPC‑DS tables using the permitted join keys and aggregates key measures.
*/
WITH cust_demo AS (
    SELECT
        c.c_customer_sk,
        cd.cd_demo_sk,
        cd.cd_dep_employed_count
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
store_ret AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_ship_cost
    FROM tpcds.store_returns sr
    WHERE sr.sr_return_tax > 10.00
),
web AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_list_price,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt
    FROM tpcds.web_sales ws
    WHERE ws.ws_list_price > 50.00
)
SELECT
    s.s_store_name,
    sm.sm_carrier,
    w.w_city,
    COUNT(DISTINCT cd.c_customer_sk)                     AS distinct_customers,
    SUM(sr.sr_return_amt)                               AS total_return_amount,
    SUM(ws.ws_net_paid)                                 AS total_sales_amount,
    AVG(ws.ws_ext_discount_amt)                         AS avg_discount,
    MIN(sr.sr_return_tax)                               AS min_return_tax,
    MAX(ws.ws_list_price)                               AS max_list_price
FROM cust_demo cd
JOIN store_ret sr
    ON sr.sr_customer_sk = cd.c_customer_sk
JOIN web ws
    ON ws.ws_bill_customer_sk = cd.c_customer_sk
JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE cd.cd_dep_employed_count >= 3
  AND s.s_state = 'CA'
GROUP BY s.s_store_name, sm.sm_carrier, w.w_city
ORDER BY total_sales_amount DESC
LIMIT 100
