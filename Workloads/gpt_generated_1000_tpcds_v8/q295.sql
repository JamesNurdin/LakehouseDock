WITH
  -- aggregate inventory per item‑warehouse (used later)
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_date_sk IN (
      SELECT d_date_sk
      FROM date_dim
      WHERE d_year = 2001
    )
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  -- core join that brings together every selected table
  base AS (
    SELECT
      d.d_year,
      i.i_item_id,
      i.i_current_price,
      w.w_state,
      sm.sm_type,
      r.r_reason_desc,
      p.p_discount_active,
      t.t_hour,
      sr.sr_return_amt,
      cr.cr_return_amount,
      ws.ws_net_paid,
      ws.ws_ext_sales_price,
      wp.wp_url,
      inv_agg.total_on_hand,
      -- scalar sub‑query: max current price for the chosen brand
      (SELECT MAX(i2.i_current_price)
       FROM item i2
       WHERE i2.i_brand = 'Brand#23') AS max_brand_price,
      -- categorise sales amount
      CASE WHEN ws.ws_net_paid > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
      -- window function: rank rows within the same year by net paid
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM date_dim d
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN (
      SELECT *
      FROM item
      TABLESAMPLE BERNOULLI (10)
    ) i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_item_sk = i.i_item_sk
     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN inv_agg
      ON inv_agg.inv_item_sk = i.i_item_sk
     AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND t.t_hour = 12
      AND i.i_brand = 'Brand#23'
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Damaged'
      AND p.p_discount_active = 'Y'
  ),
  -- two filtered slices that will be UNION‑ed
  slice_a AS (
    SELECT * FROM base WHERE r_reason_desc = 'Damaged'
  ),
  slice_b AS (
    SELECT * FROM base WHERE r_reason_desc = 'Defective'
  ),
  unioned AS (
    SELECT * FROM slice_a
    UNION DISTINCT
    SELECT * FROM slice_b
  )
SELECT
  d_year,
  i_item_id,
  w_state,
  COUNT(*) AS row_cnt,
  SUM(sr_return_amt) AS total_store_return_amt,
  SUM(cr_return_amount) AS total_catalog_return_amt,
  SUM(ws_net_paid) AS total_sales_net_paid,
  SUM(ws_ext_sales_price) AS total_sales_ext_price,
  AVG(i_current_price) AS avg_item_price,
  MAX(max_brand_price) AS max_brand_price_overall,
  SUM(CASE WHEN sales_category = 'High' THEN ws_net_paid ELSE 0 END) AS high_value_sales,
  MIN(total_on_hand) AS min_inventory_on_hand,
  MAX(sales_rank) AS max_sales_rank
FROM unioned
GROUP BY d_year, i_item_id, w_state
ORDER BY total_sales_net_paid DESC
LIMIT 100
