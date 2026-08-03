WITH
  -- Active promotions used for filtering
  promo_active AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
  ),

  -- Catalog sales with many dimension joins and filter on active promotions
  sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_item_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_promo_sk,
      d.d_year,
      d.d_month_seq,
      t.t_hour,
      c.c_customer_sk,
      cc.cc_class,
      cp.cp_department,
      sm.sm_type,
      w.w_state,
      p.p_promo_id
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_promo_sk IN (SELECT p_promo_sk FROM promo_active)
  ),

  -- Returns linked back to the sale order and its own dimensions
  returns AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      d_ret.d_year AS ret_year,
      sm_ret.sm_type AS ret_ship_type,
      w_ret.w_state AS ret_state,
      cp_ret.cp_department AS ret_department
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
  ),

  -- Inventory snapshots joined to date and warehouse
  inventory_data AS (
    SELECT
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      d_inv.d_year,
      w_inv.w_state
    FROM inventory i
    JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
  ),

  -- Store sales with its own set of dimensions
  store_data AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      d_s.d_year,
      t_s.t_hour,
      c_s.c_customer_sk,
      s.s_state,
      p_s.p_promo_id
    FROM store_sales ss
    JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
    JOIN customer c_s ON ss.ss_customer_sk = c_s.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_s ON ss.ss_promo_sk = p_s.p_promo_sk
  ),

  -- Expand promotion channels (array unnest example)
  promo_channels AS (
    SELECT
      p.p_promo_sk,
      channel
    FROM promotion p
    CROSS JOIN UNNEST(ARRAY[
      p.p_channel_email,
      p.p_channel_tv,
      p.p_channel_radio,
      p.p_channel_catalog
    ]) AS t(channel)
    WHERE channel IS NOT NULL
  ),

  -- Example of EXCEPT: order numbers that appear in sales but not in returns
  order_diff AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  )

SELECT
  d_year,
  s_state,
  cc_class,
  cp_department,
  sm_type,
  SUM(total_sales)        AS total_sales,
  SUM(total_returns)      AS total_returns,
  SUM(total_inventory)    AS total_inventory,
  COUNT(DISTINCT item_sk) AS distinct_items,
  ARRAY_AGG(DISTINCT promo_id) AS promotions
FROM (
  -- Catalog sales rows
  SELECT
    s.d_year,
    st.s_state,
    s.cc_class,
    s.cp_department,
    s.sm_type,
    s.cs_net_paid          AS total_sales,
    0.0                    AS total_returns,
    0                      AS total_inventory,
    s.cs_item_sk           AS item_sk,
    s.p_promo_id           AS promo_id
  FROM sales s
  LEFT JOIN store_data st
    ON s.cs_sold_date_sk = st.ss_sold_date_sk
   AND s.cs_sold_time_sk = st.ss_sold_time_sk

  UNION ALL

  -- Return rows
  SELECT
    r.ret_year,
    r.ret_state,
    NULL,
    r.ret_department,
    r.ret_ship_type,
    0.0,
    r.cr_return_amount,
    0,
    NULL,
    NULL
  FROM returns r

  UNION ALL

  -- Inventory rows
  SELECT
    i.d_year,
    i.w_state,
    NULL,
    NULL,
    NULL,
    0.0,
    0.0,
    i.inv_quantity_on_hand,
    i.inv_item_sk,
    NULL
  FROM inventory_data i
) AS combined
GROUP BY CUBE (d_year, s_state, cc_class, cp_department, sm_type)
HAVING SUM(total_sales) > 0
ORDER BY d_year DESC, s_state, total_sales DESC
LIMIT 100
