/* goal: Analyze sales performance per call center and state, accounting for returns and web returns, and filter out orders with very large return amounts. */
WITH cs_summary AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ca_bill.ca_address_sk      AS bill_address_sk,
        ca_bill.ca_state           AS bill_state,
        cc.cc_name,
        td.t_hour,
        td.t_am_pm
    FROM catalog_sales cs
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825               -- surrogate date range (approx. 10 days)
      AND cc.cc_state = 'CA'                                          -- call center located in California
      AND td.t_hour BETWEEN 9 AND 17                                 -- business hours
      AND cs.cs_quantity > 10                                        -- fairly large orders
      AND cs.cs_ext_sales_price > 100.00                             -- high‑value sales
)
SELECT
    cs_s.cs_call_center_sk,
    cs_s.cc_name,
    cs_s.bill_state,
    COUNT(DISTINCT cs_s.cs_order_number)               AS order_cnt,
    SUM(cs_s.cs_ext_sales_price)                       AS total_sales,
    SUM(cs_s.cs_net_profit)                            AS total_profit,
    SUM(COALESCE(cr.cr_return_amount, 0))              AS total_return_amount,
    COUNT(cr.cr_return_quantity)                       AS return_cnt,
    AVG(cs_s.cs_quantity)                              AS avg_quantity,
    MAX(cs_s.t_hour)                                   AS max_hour
FROM cs_summary cs_s
LEFT JOIN catalog_returns cr
  ON cs_s.cs_order_number = cr.cr_order_number
  AND cs_s.cs_item_sk      = cr.cr_item_sk
  AND cs_s.cs_call_center_sk = cr.cr_call_center_sk
  AND cs_s.cs_sold_time_sk   = cr.cr_returned_time_sk
LEFT JOIN web_returns wr
  ON cs_s.cs_sold_time_sk   = wr.wr_returned_time_sk
  AND cs_s.bill_address_sk  = wr.wr_refunded_addr_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs_s.cs_order_number
      AND cr2.cr_return_amount > 5000.00
)
GROUP BY
    cs_s.cs_call_center_sk,
    cs_s.cc_name,
    cs_s.bill_state,
    cs_s.t_hour
ORDER BY total_sales DESC
LIMIT 100
