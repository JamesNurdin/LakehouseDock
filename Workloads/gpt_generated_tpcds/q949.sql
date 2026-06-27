WITH aggregated AS (
  SELECT
    td.t_hour,
    sm.sm_type,
    wp.wp_type,
    hd.hd_buy_potential,
    i.i_category,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    SUM(ws.ws_net_profit) AS total_net_profit
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY
    td.t_hour,
    sm.sm_type,
    wp.wp_type,
    hd.hd_buy_potential,
    i.i_category
),
ranked AS (
  SELECT
    t_hour,
    sm_type,
    wp_type,
    hd_buy_potential,
    i_category,
    total_quantity,
    total_discount_amount,
    total_net_profit,
    round(100.0 * total_net_profit / sum(total_net_profit) OVER (PARTITION BY t_hour, sm_type), 2) AS profit_pct_of_hour_mode,
    row_number() OVER (PARTITION BY t_hour, sm_type ORDER BY total_net_profit DESC) AS category_rank
  FROM aggregated
)
SELECT
  t_hour,
  sm_type,
  wp_type,
  hd_buy_potential,
  i_category,
  total_quantity,
  total_discount_amount,
  total_net_profit,
  profit_pct_of_hour_mode,
  category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY t_hour, sm_type, category_rank
