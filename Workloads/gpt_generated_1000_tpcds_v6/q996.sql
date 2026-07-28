WITH inv AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    AVG(cs.cs_ext_sales_price) AS avg_catalog_sales_price,
    MAX(ss.ss_ext_sales_price) AS max_store_sale_price,
    MIN(wr.wr_return_amt) AS min_web_return_amt,
    (SELECT AVG(cc_sub.cc_gmt_offset)
       FROM call_center cc_sub
       WHERE cc_sub.cc_state = s.s_state) AS avg_gmt_offset_state,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN inv
  ON d.d_date_sk = inv.inv_date_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_store_sk = s.s_store_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 1912
  AND s.s_state = 'CA'
  AND cc.cc_market_manager = 'Jane Smith'
  AND ss.ss_ext_sales_price > 1000
GROUP BY s.s_store_id, s.s_store_name, d.d_year, s.s_state
HAVING SUM(ss.ss_net_paid) > 5000
ORDER BY total_store_net_paid DESC
LIMIT 100
