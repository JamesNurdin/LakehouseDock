WITH
  inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
  ),
  inv_raw AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
  )

/* 1st pathway – catalog_sales */
SELECT
  d.d_year,
  i.i_item_id,
  i.i_product_name,
  s.s_store_name,
  cs.cs_ext_sales_price,
  inv_agg.total_on_hand,
  (
    SELECT SUM(ws_sub.ws_ext_sales_price)
    FROM web_sales ws_sub
    WHERE ws_sub.ws_bill_customer_sk = c.c_customer_sk
  ) AS cust_web_sales_total,
  t.t_hour
FROM
  catalog_sales cs
  RIGHT OUTER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
  LEFT JOIN inv_raw ir ON i.i_item_sk = ir.inv_item_sk
  FULL OUTER JOIN (
    SELECT sr.sr_item_sk,
           sr.sr_store_sk,
           sr.sr_return_amt
    FROM store_returns sr
  ) sr ON sr.sr_item_sk = i.i_item_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE
  d.d_year = 2001
  AND p.p_discount_active = 'Y'

UNION DISTINCT

/* 2nd pathway – web_sales */
SELECT
  d2.d_year,
  i2.i_item_id,
  i2.i_product_name,
  s2.s_store_name,
  ws.ws_ext_sales_price,
  inv_agg2.total_on_hand,
  (
    SELECT SUM(ws_sub2.ws_ext_sales_price)
    FROM web_sales ws_sub2
    WHERE ws_sub2.ws_bill_customer_sk = c2.c_customer_sk
  ) AS cust_web_sales_total,
  t2.t_hour
FROM
  web_sales ws
  LEFT JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
  JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
  JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
  JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
  JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
  JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
  JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
  LEFT JOIN inv_agg inv_agg2 ON i2.i_item_sk = inv_agg2.inv_item_sk
  LEFT JOIN inv_raw ir2 ON i2.i_item_sk = ir2.inv_item_sk
  FULL OUTER JOIN (
    SELECT sr2.sr_item_sk,
           sr2.sr_store_sk,
           sr2.sr_return_amt
    FROM store_returns sr2
  ) sr2 ON sr2.sr_item_sk = i2.i_item_sk
  LEFT JOIN store s2 ON sr2.sr_store_sk = s2.s_store_sk
WHERE
  d2.d_year = 2001
  AND p2.p_discount_active = 'Y'

EXCEPT

/* Sub‑set to be removed – pure store_returns view */
SELECT
  d3.d_year,
  i3.i_item_id,
  i3.i_product_name,
  s3.s_store_name,
  CAST(NULL AS decimal(7,2)) AS cs_ext_sales_price,
  inv_agg3.total_on_hand,
  CAST(NULL AS decimal(7,2)) AS cust_web_sales_total,
  t3.t_hour
FROM
  store_returns sr3
  JOIN date_dim d3 ON sr3.sr_returned_date_sk = d3.d_date_sk
  JOIN time_dim t3 ON sr3.sr_return_time_sk = t3.t_time_sk
  JOIN item i3 ON sr3.sr_item_sk = i3.i_item_sk
  LEFT JOIN inv_agg inv_agg3 ON i3.i_item_sk = inv_agg3.inv_item_sk
  LEFT JOIN store s3 ON sr3.sr_store_sk = s3.s_store_sk

ORDER BY
  d_year DESC,
  cs_ext_sales_price DESC
LIMIT 100
