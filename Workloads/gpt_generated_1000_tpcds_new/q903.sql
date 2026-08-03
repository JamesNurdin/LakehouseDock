WITH
  -- Customers who made a store purchase in 2001 but never a web purchase in 2001
  cust_only_store AS (
    SELECT DISTINCT c.c_customer_sk
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_sold_date_sk IN (
      SELECT d_date_sk FROM tpcds.date_dim WHERE d_year = 2001
    )
    EXCEPT
    SELECT DISTINCT c.c_customer_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk IN (
      SELECT d_date_sk FROM tpcds.date_dim WHERE d_year = 2001
    )
  ),
  -- Alias for date dimension used for store_sales
  d_sold AS (
    SELECT * FROM tpcds.date_dim
  ),
  -- Alias for date dimension used for web_sales (ship date)
  d_ws AS (
    SELECT * FROM tpcds.date_dim
  ),
  -- Alias for time dimension used for store_sales
  t_sold AS (
    SELECT * FROM tpcds.time_dim
  ),
  -- Alias for time dimension used for web_sales
  t_ws AS (
    SELECT * FROM tpcds.time_dim
  )
SELECT DISTINCT
  c.c_customer_id,
  s.s_store_name,
  CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  ws_agg.total_web_sales,
  sr_agg.total_returns,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  d_sold.d_year AS sale_year,
  t_sold.t_hour AS sale_hour
FROM tpcds.store_sales ss
JOIN d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
-- Filter stores in California and with reasonable GMT offset
JOIN tpcds.store s_filter ON s.s_store_sk = s_filter.s_store_sk
  AND s_filter.s_state = 'CA'
  AND s_filter.s_gmt_offset BETWEEN -5.0 AND 5.0
-- Only keep customers identified in the CTE
JOIN cust_only_store cos ON c.c_customer_sk = cos.c_customer_sk
-- Join store_returns (ticket and item link to the same sale) and reason
JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
  AND r.r_reason_desc = 'Damaged'
-- Join web_sales for the same customer (bill side)
JOIN tpcds.web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
-- LATERAL subquery: total web sales per customer
LEFT JOIN LATERAL (
  SELECT SUM(ws_inner.ws_net_paid) AS total_web_sales
  FROM tpcds.web_sales ws_inner
  WHERE ws_inner.ws_bill_customer_sk = c.c_customer_sk
) ws_agg ON TRUE
-- LATERAL subquery: total returns per customer
LEFT JOIN LATERAL (
  SELECT SUM(sr_inner.sr_net_loss) AS total_returns
  FROM tpcds.store_returns sr_inner
  WHERE sr_inner.sr_customer_sk = c.c_customer_sk
) sr_agg ON TRUE
WHERE EXISTS (
  SELECT 1 FROM tpcds.store s2
  WHERE s2.s_store_id IN (
    SELECT s3.s_store_id FROM tpcds.store s3 WHERE s3.s_floor_space > 200000
  )
  AND s2.s_store_sk = s.s_store_sk
)
ORDER BY ws_agg.total_web_sales DESC
OFFSET 20 ROWS FETCH NEXT 100 ROWS ONLY
