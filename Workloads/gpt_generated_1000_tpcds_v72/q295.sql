WITH base AS (
  SELECT
    c.c_customer_id,
    i.i_product_name,
    d.d_year,
    t.t_meal_time,
    s.s_store_name,
    w.w_warehouse_name,
    r.r_reason_desc,
    SUM(cs.cs_ext_sales_price)        AS catalog_sales,
    SUM(ss.ss_ext_sales_price)        AS store_sales,
    SUM(ws.ws_ext_sales_price)        AS web_sales,
    SUM(sr.sr_return_amt)             AS store_return_amount,
    SUM(wr.wr_return_amt)             AS web_return_amount,
    SUM(inv.inv_quantity_on_hand)     AS inventory_on_hand
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
   AND ss.ss_item_sk = i.i_item_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_item_sk = i.i_item_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 2001
    AND t.t_meal_time = 'dinner'
    AND ca.ca_state = 'CA'
    AND i.i_manufact_id IN (220, 214)
  GROUP BY
    c.c_customer_id,
    i.i_product_name,
    d.d_year,
    t.t_meal_time,
    s.s_store_name,
    w.w_warehouse_name,
    r.r_reason_desc
)
SELECT
  DISTINCT
  c_customer_id,
  i_product_name,
  d_year,
  t_meal_time,
  s_store_name,
  w_warehouse_name,
  r_reason_desc,
  catalog_sales,
  store_sales,
  web_sales,
  store_return_amount,
  web_return_amount,
  inventory_on_hand,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY catalog_sales DESC) AS catalog_sales_rank
FROM base
ORDER BY catalog_sales DESC
LIMIT 100
