SELECT
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    ca_bill.ca_state,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'High Volume' ELSE 'Normal Volume' END AS volume_category,
    (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_item_sales_price
FROM catalog_sales cs
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN customer c_ret ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN time_dim t_wr_return ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_sales.d_year = 2001
  AND i.i_category = 'Sports'
  AND ca_bill.ca_state = 'CA'
  AND r.r_reason_desc = 'Damaged'
  AND w.w_warehouse_name = 'Warehouse A'
  AND t_sales.t_hour BETWEEN 9 AND 17
  AND cs.cs_quantity > 2
GROUP BY i.i_category, i.i_brand, r.r_reason_desc, ca_bill.ca_state, i.i_item_sk
ORDER BY total_sales_amount DESC
LIMIT 100
