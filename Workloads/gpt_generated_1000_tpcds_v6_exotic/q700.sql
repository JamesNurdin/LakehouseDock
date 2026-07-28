WITH
  sales_agg AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_hdemo_sk,
      ss.ss_customer_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_quantity) AS total_qty
    FROM tpcds.store_sales ss
    GROUP BY
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_hdemo_sk,
      ss.ss_customer_sk
  ),
  store_returns_agg AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      sr.sr_customer_sk,
      SUM(sr.sr_return_quantity) AS store_return_qty,
      SUM(sr.sr_return_amt) AS store_return_amount,
      MAX(r.r_reason_desc) AS store_return_reason_desc
    FROM tpcds.store_returns sr
    JOIN tpcds.reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      sr.sr_customer_sk
  ),
  catalog_returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_return_quantity) AS catalog_return_qty,
      SUM(cr.cr_return_amount) AS catalog_return_amount,
      MAX(cc.cc_name)                AS call_center_name,
      MAX(cp.cp_description)         AS catalog_page_desc,
      MAX(sm.sm_type)                AS ship_mode_type,
      MAX(r.r_reason_desc)           AS catalog_return_reason_desc
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY
      cr.cr_item_sk,
      cr.cr_returned_date_sk
  ),
  inventory_agg AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_date_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM tpcds.inventory inv
    GROUP BY
      inv.inv_item_sk,
      inv.inv_date_sk
  )
SELECT
  s.s_store_id,
  s.s_store_name,
  i.i_item_id,
  i.i_product_name,
  d_sales.d_date            AS sales_date,
  d_closed.d_date           AS store_closed_date,
  c_sales.c_first_name,
  c_ret.c_first_name        AS return_customer_first_name,
  hd.hd_buy_potential,
  sa.total_sales,
  sa.total_qty,
  COALESCE(sr_agg.store_return_qty, 0)               AS store_return_qty,
  COALESCE(sr_agg.store_return_amount, 0)           AS store_return_amount,
  sr_agg.store_return_reason_desc,
  COALESCE(cr_agg.catalog_return_qty, 0)            AS catalog_return_qty,
  COALESCE(cr_agg.catalog_return_amount, 0)        AS catalog_return_amount,
  cr_agg.call_center_name,
  cr_agg.catalog_page_desc,
  cr_agg.ship_mode_type,
  cr_agg.catalog_return_reason_desc,
  COALESCE(inv_agg.total_on_hand, 0)               AS inventory_on_hand
FROM sales_agg sa
JOIN tpcds.item i
  ON sa.ss_item_sk = i.i_item_sk
JOIN tpcds.store s
  ON sa.ss_store_sk = s.s_store_sk
JOIN tpcds.date_dim d_sales
  ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN tpcds.date_dim d_closed
  ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN tpcds.customer c_sales
  ON sa.ss_customer_sk = c_sales.c_customer_sk
JOIN tpcds.household_demographics hd
  ON sa.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns_agg sr_agg
  ON sr_agg.sr_item_sk = sa.ss_item_sk
 AND sr_agg.sr_returned_date_sk = sa.ss_sold_date_sk
LEFT JOIN tpcds.customer c_ret
  ON sr_agg.sr_customer_sk = c_ret.c_customer_sk
LEFT JOIN catalog_returns_agg cr_agg
  ON cr_agg.cr_item_sk = sa.ss_item_sk
 AND cr_agg.cr_returned_date_sk = sa.ss_sold_date_sk
LEFT JOIN inventory_agg inv_agg
  ON inv_agg.inv_item_sk = sa.ss_item_sk
 AND inv_agg.inv_date_sk = sa.ss_sold_date_sk
ORDER BY s.s_store_id, d_sales.d_date DESC
LIMIT 100
