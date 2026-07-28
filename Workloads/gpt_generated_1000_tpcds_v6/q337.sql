WITH base AS (
  SELECT DISTINCT
    cp.cp_catalog_page_sk,
    cp.cp_catalog_page_id,
    cp.cp_department,
    p.p_promo_id,
    p.p_response_target,
    p.p_channel_catalog,
    sm.sm_type,
    w.w_state,
    w.w_gmt_offset,
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_list_price,
    cs.cs_wholesale_cost,
    cr.cr_net_loss,
    t_sold.t_shift AS sold_shift,
    t_ret.t_shift AS return_shift
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  LEFT JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
  WHERE
    cp.cp_department = 'Sports'
    AND p.p_response_target > 0
    AND p.p_channel_catalog = 'Y'
    AND cs.cs_list_price > 50
    AND cs.cs_wholesale_cost < 50
    AND sm.sm_type IN ('AIR','GROUND')
    AND w.w_gmt_offset BETWEEN -5 AND 5
),
agg AS (
  SELECT
    cp_catalog_page_sk,
    cp_catalog_page_id,
    p_promo_id,
    sm_type,
    w_state,
    SUM(cs_net_profit) AS profit_sum,
    SUM(COALESCE(cr_net_loss, 0)) AS loss_sum,
    SUM(cs_ext_sales_price) AS sales_sum,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(cs_quantity) AS qty_sum
  FROM base
  GROUP BY
    cp_catalog_page_sk,
    cp_catalog_page_id,
    p_promo_id,
    sm_type,
    w_state
)
SELECT
  cp_catalog_page_id,
  p_promo_id,
  sm_type,
  w_state,
  profit_sum,
  loss_sum,
  sales_sum,
  distinct_orders,
  qty_sum
FROM agg
WHERE profit_sum > loss_sum
  AND distinct_orders > 5
  AND sales_sum > 1000
  AND qty_sum >= 10
  AND w_state IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    JOIN time_dim t2 ON cr2.cr_returned_time_sk = t2.t_time_sk
    WHERE cr2.cr_catalog_page_sk = agg.cp_catalog_page_sk
      AND t2.t_shift = 'night'
  )
ORDER BY profit_sum DESC
LIMIT 100
