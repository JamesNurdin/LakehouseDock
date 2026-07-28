WITH store_sales_agg AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_sold_date_sk,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_net_paid,
    COUNT(*) AS store_txn_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND cd.cd_gender = 'M'
    AND hd.hd_buy_potential = '>10000'
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND ca.ca_country = 'United States'
  GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
)
SELECT
  i.i_item_id,
  i.i_product_name,
  d.d_year,
  sa.total_store_sales,
  sa.total_store_net_paid,
  COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(ws.ws_net_paid_inc_tax) AS total_web_net_paid,
  AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
  sm.sm_type AS ship_mode_type,
  wp.wp_type AS web_page_type,
  we.web_name AS website_name
FROM store_sales_agg sa
JOIN web_sales ws
  ON ws.ws_item_sk = sa.ss_item_sk
  AND ws.ws_sold_date_sk = sa.ss_sold_date_sk
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer_address ca2
  ON ws.ws_bill_addr_sk = ca2.ca_address_sk
WHERE sm.sm_type = 'AIR'
  AND wp.wp_type = 'Content'
  AND we.web_country = 'United States'
  AND EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = sa.ss_item_sk
      AND sr.sr_returned_date_sk = sa.ss_sold_date_sk
      AND sr.sr_return_amt > 0
  )
  AND ws.ws_order_number IN (
    SELECT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
  )
GROUP BY
  i.i_item_id,
  i.i_product_name,
  d.d_year,
  sa.total_store_sales,
  sa.total_store_net_paid,
  sm.sm_type,
  wp.wp_type,
  we.web_name
ORDER BY total_store_sales DESC
LIMIT 100
