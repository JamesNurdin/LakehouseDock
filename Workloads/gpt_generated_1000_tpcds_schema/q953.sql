/*
Goal: Identify high‑value web customers whose email domain matches a pattern, link them to catalog sales data (including call‑center info) via a full outer join, flag orders that never had a return, and categorize sales levels using CASE logic. The query demonstrates regex processing, LIKE pattern matching, string concatenation, a subquery, EXCEPT set subtraction, and aggregation.
*/
WITH cs_cc AS (
    SELECT
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_net_paid,
        cc.cc_name,
        cc.cc_state
    FROM catalog_sales cs
    FULL OUTER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
),
orders_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales,
        CASE
            WHEN SUM(ws.ws_net_paid_inc_ship) > 10000 THEN 'HIGH'
            WHEN SUM(ws.ws_net_paid_inc_ship) > 5000  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_category
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^.*@example\\.com$')
      AND ws.ws_ship_mode_sk IN (
            SELECT sm_ship_mode_sk
            FROM ship_mode
            WHERE sm_type LIKE 'AIR%'
        )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    cs_cc.cs_order_number,
    cs_cc.cc_name,
    cs_cc.cc_state,
    cs_cc.cs_net_paid,
    cust.full_name,
    cust.total_sales,
    cust.sales_category,
    CASE
        WHEN cs_cc.cs_order_number IS NULL THEN 'No Catalog Sale'
        WHEN cust.c_customer_sk IS NULL THEN 'No Web Sale'
        ELSE 'Both'
    END AS data_source
FROM cs_cc
LEFT JOIN customer_sales cust
    ON cs_cc.cs_bill_customer_sk = cust.c_customer_sk
WHERE cs_cc.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
  AND cs_cc.cc_name IS NOT NULL
  AND REGEXP_EXTRACT(cs_cc.cc_name, '(\\w+)') = 'Central'
  AND cs_cc.cc_state LIKE 'CA%'
ORDER BY cust.total_sales DESC NULLS LAST, cs_cc.cs_order_number
LIMIT 100
