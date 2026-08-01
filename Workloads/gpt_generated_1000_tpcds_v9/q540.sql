WITH distinct_store_reason AS (
    SELECT DISTINCT s.s_store_sk, r.r_reason_sk
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
)
SELECT
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    r.r_reason_desc AS return_reason,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    MIN(cs.cs_ext_ship_cost) AS min_ship_cost,
    MAX(cs.cs_ext_ship_cost) AS max_ship_cost,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_store_sk = s.s_store_sk) AS total_returns_for_store
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN distinct_store_reason dsr ON dsr.s_store_sk = s.s_store_sk AND dsr.r_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_returning_customer_sk = c.c_customer_sk
   AND cr.cr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = cr.cr_item_sk
   AND cs.cs_order_number = cr.cr_order_number
   AND cs.cs_bill_customer_sk = c.c_customer_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE 
    s.s_state = 'CA'
    AND cs.cs_sales_price > 100
    AND sr.sr_refunded_cash < 500
    AND sr.sr_return_quantity BETWEEN 5 AND 20
    AND s.s_rec_start_date >= DATE '1998-01-01'
    AND EXISTS (
        SELECT 1 FROM call_center cc
        WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
          AND cc.cc_name = 'Central Call Center'
    )
GROUP BY
    s.s_store_name,
    s.s_state,
    r.r_reason_desc,
    s.s_store_sk,
    s.s_rec_start_date
ORDER BY total_return_amount DESC
LIMIT 100
