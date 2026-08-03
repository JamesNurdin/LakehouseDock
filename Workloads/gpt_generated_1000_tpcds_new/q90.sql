WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 1000
),
cr AS (
    SELECT
        cr.cr_order_number,
        cr.cr_refunded_customer_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 10
),
ss AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        ss.ss_net_paid,
        ss.ss_ext_sales_price
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
      AND ss.ss_net_paid > 1000
),
sr AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_reason_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 50
),
common_customers AS (
    SELECT c.c_customer_id
    FROM cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    INTERSECT
    SELECT c.c_customer_id
    FROM ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
)
SELECT
    sm.sm_type,
    r.r_reason_desc,
    carrier,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_paid) AS avg_net_paid,
    MIN(cr.cr_return_amount) AS min_return_amt,
    MAX(sr.sr_return_amt) AS max_store_return_amt
FROM cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN UNNEST(ARRAY[sm.sm_carrier]) AS t(carrier)
WHERE c.c_customer_id IN (SELECT c_customer_id FROM common_customers)
  AND cs.cs_ext_sales_price > (
        SELECT MAX(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_return_quantity > 0
      )
GROUP BY sm.sm_type, r.r_reason_desc, carrier
ORDER BY total_sales DESC
LIMIT 100
