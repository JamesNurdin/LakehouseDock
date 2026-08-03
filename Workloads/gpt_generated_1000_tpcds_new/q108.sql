WITH
  return_summary AS (
    SELECT
      cr_item_sk,
      cr_returned_date_sk,
      SUM(cr_return_quantity) AS total_return_qty,
      SUM(cr_return_amount)   AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_returned_date_sk
  )
SELECT
  d_ret.d_year,
  i.i_category,
  i.i_brand,
  ws.ws_net_profit,
  rs.total_return_amount,
  w.w_warehouse_name,
  cc.cc_name,
  sm.sm_type,
  r.r_reason_desc,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  sales_cnt.sales_count,
  inv_lat.total_inventory
FROM return_summary rs
-- core catalog_returns row to bring in foreign keys
JOIN catalog_returns cr
  ON cr.cr_item_sk = rs.cr_item_sk
 AND cr.cr_returned_date_sk = rs.cr_returned_date_sk
-- date of the return
JOIN date_dim d_ret
  ON rs.cr_returned_date_sk = d_ret.d_date_sk
-- item details
JOIN item i
  ON rs.cr_item_sk = i.i_item_sk
-- warehouse where the return was processed
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
-- call centre handling the return
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
-- ship mode used for the return
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
-- reason for the return
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
-- household demographics of the refunded customer
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
-- income band for that household
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
-- refunded customer
JOIN customer c_refunded
  ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
-- demographics of the refunded customer
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
-- returning customer (different role, same table under another alias)
JOIN customer c_returning
  ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
-- web sales that involve the same item (adds many more joins)
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
-- store linked through its closed‑date dimension (reuse date_dim alias)
JOIN store s
  ON s.s_closed_date_sk = d_ret.d_date_sk
-- lateral subquery: total inventory for the item/warehouse pair
CROSS JOIN LATERAL (
  SELECT SUM(inv_quantity_on_hand) AS total_inventory
  FROM inventory inv2
  WHERE inv2.inv_item_sk = i.i_item_sk
    AND inv2.inv_warehouse_sk = w.w_warehouse_sk
) inv_lat
-- scalar subquery to count sales of the item on the sold date
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS sales_count
  FROM web_sales ws2
  WHERE ws2.ws_item_sk = i.i_item_sk
    AND ws2.ws_sold_date_sk = d_sold.d_date_sk
) sales_cnt ON TRUE
WHERE d_ret.d_year = 2001
  AND p.p_channel_tv = 'N'
  AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_id = r.r_reason_id
          AND r2.r_reason_desc LIKE '%defect%'
      )
ORDER BY d_ret.d_year, rs.total_return_amount DESC
LIMIT 100
