WITH base AS (
  SELECT
    d_ret.d_year,
    d_ret.d_day_name,
    i.i_item_id,
    i.i_current_price,
    i.i_units,
    cc.cc_name,
    cc.cc_state,
    sm.sm_type,
    ws.ws_sales_price,
    ws.ws_quantity,
    ws.ws_net_profit,
    cr.cr_return_amount,
    cr.cr_net_loss,
    CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_sales ws ON cr.cr_item_sk = ws.ws_item_sk
  JOIN date_dim d_sal ON ws.ws_sold_date_sk = d_sal.d_date_sk
  JOIN time_dim t_sal ON ws.ws_sold_time_sk = t_sal.t_time_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE d_ret.d_year = 2001
    AND i.i_current_price BETWEEN 5 AND 100
    AND cc.cc_state = 'CA'
    AND sm.sm_type IN ('AIR', 'RAIL')
    AND t_ret.t_hour >= 8
    AND we.web_state = 'CA'
    AND EXISTS (
      SELECT 1 FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
        AND inv.inv_quantity_on_hand > 200
    )
),
union_set AS (
  SELECT
    d_year,
    d_day_name,
    i_item_id,
    ws_sales_price,
    ws_quantity,
    ws_net_profit,
    cr_return_amount,
    cr_net_loss,
    profit_flag
  FROM base
  WHERE profit_flag = 'PROFIT' AND i_units = 'Box'
  UNION DISTINCT
  SELECT
    d_year,
    d_day_name,
    i_item_id,
    ws_sales_price,
    ws_quantity,
    ws_net_profit,
    cr_return_amount,
    cr_net_loss,
    profit_flag
  FROM base
  WHERE profit_flag = 'LOSS' AND i_units = 'Dozen'
),
full_outer AS (
  SELECT
    inv.inv_date_sk,
    inv.inv_quantity_on_hand,
    d_full.d_year,
    d_full.d_day_name
  FROM inventory inv
  FULL OUTER JOIN date_dim d_full
    ON inv.inv_date_sk = d_full.d_date_sk
  WHERE d_full.d_year BETWEEN 2000 AND 2002
    AND inv.inv_quantity_on_hand IS NOT NULL
)
SELECT
  us.d_year,
  us.d_day_name,
  COUNT(DISTINCT us.i_item_id) AS distinct_items,
  SUM(us.ws_sales_price) AS total_sales,
  SUM(us.cr_return_amount) AS total_returns,
  AVG(us.ws_net_profit) AS avg_profit,
  SUM(CASE WHEN us.profit_flag = 'PROFIT' THEN us.ws_sales_price ELSE 0 END) AS profit_sales,
  SUM(CASE WHEN us.profit_flag = 'LOSS' THEN us.ws_sales_price ELSE 0 END) AS loss_sales
FROM union_set us
JOIN full_outer fo
  ON fo.d_year = us.d_year
GROUP BY us.d_year, us.d_day_name
HAVING SUM(us.ws_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
