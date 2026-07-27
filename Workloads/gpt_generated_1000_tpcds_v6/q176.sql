SELECT
    s.s_store_name,
    ca.ca_city,
    r.r_reason_desc,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(ws.ws_net_paid_inc_tax) AS avg_web_net_paid,
    CASE
        WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_category
FROM store_sales ss
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN web_sales ws
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE ca.ca_state = 'CA'
  AND s.s_state = 'TX'
  AND r.r_reason_desc LIKE '%warranty%'
  AND ss.ss_quantity > 5
  AND ws.ws_net_paid_inc_tax > 1000
  AND wr.wr_return_quantity = 1
GROUP BY s.s_store_name, ca.ca_city, r.r_reason_desc
ORDER BY total_return_amount DESC, s.s_store_name ASC
LIMIT 100
