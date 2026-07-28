SELECT
    d_sold.d_year AS sales_year,
    p.p_channel_catalog AS promo_channel,
    sm.sm_type AS ship_type,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    SUM(CASE WHEN sm.sm_type = 'OVERNIGHT' THEN cs.cs_ext_sales_price ELSE 0 END) AS overnight_catalog_sales
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store_sales ss
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_store
  ON ss.ss_sold_date_sk = d_store.d_date_sk
JOIN customer_address ca_store
  ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN store_returns sr
  ON sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_return
  ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_sr
  ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_refund
  ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
  ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
GROUP BY GROUPING SETS (
    (d_sold.d_year, p.p_channel_catalog, sm.sm_type),
    (d_sold.d_year, p.p_channel_catalog),
    (d_sold.d_year),
    ()
)
LIMIT 100
