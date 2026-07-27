/*
Goal: Identify the top call centers by total web sales amount, focusing on recent active customers who have made purchases and received refunds, and only for web pages of type 'Content' located in California. The query joins all five selected tables, applies multiple realistic filters, uses an EXISTS semi‑join, includes a DISTINCT aggregation, and limits the result to 100 rows.
*/
WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_hdemo_sk,
        c_last_review_date
    FROM tpcds.customer
    WHERE c_current_hdemo_sk IN (3446, 6018, 2373)               -- demographic filter
      AND c_last_review_date > 2452500                           -- recent review activity
)
SELECT
    cc.cc_name,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price)          AS total_sales,
    AVG(cr.cr_refunded_cash)            AS avg_refund_cash,
    MIN(ws.ws_net_profit)               AS min_profit,
    MAX(ws.ws_net_profit)               AS max_profit
FROM tpcds.call_center cc
JOIN tpcds.catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.web_sales ws
    ON ws.ws_web_page_sk = cr.cr_call_center_sk   -- indirect join via web_page later
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE EXISTS (
        SELECT 1
        FROM filtered_customers fc
        WHERE fc.c_customer_sk = cr.cr_refunded_customer_sk
          AND fc.c_customer_sk = ws.ws_bill_customer_sk
    )
  AND wp.wp_type = 'Content'                         -- only content pages
  AND wp.wp_customer_sk = cr.cr_refunded_customer_sk  -- page belongs to the refunded customer
  AND cc.cc_state = 'CA'                              -- California call centers only
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00         -- specific time‑zone range
  AND cr.cr_return_amount > 1000                      -- sizable refunds
  AND ws.ws_ext_wholesale_cost < 3000                 -- moderate wholesale cost
GROUP BY
    cc.cc_name,
    wp.wp_type
ORDER BY
    total_sales DESC
LIMIT 100
