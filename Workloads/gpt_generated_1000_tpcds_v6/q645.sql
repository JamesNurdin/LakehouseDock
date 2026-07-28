WITH joined_data AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    ss.ss_sold_date_sk,
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    inv.inv_quantity_on_hand,
    ss.ss_net_profit          AS store_net_profit,
    ws.ws_net_profit          AS web_net_profit,
    sr.sr_net_loss            AS store_return_loss,
    wr.wr_net_loss            AS web_return_loss
  FROM store_sales ss
  JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
  JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
  JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
  JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
  JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
  JOIN customer_demographics cd_wr_refunded
    ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
  JOIN household_demographics hd_wr_refunded
    ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  WHERE t_ss.t_meal_time = 'lunch'
    AND i.i_current_price > 50
    AND s.s_state = 'CA'
    AND sm.sm_type = 'AIR'
)
SELECT
  s_store_name,
  s_state,
  ss_sold_date_sk,
  i_item_id,
  i_product_name,
  SUM(store_net_profit)                     AS total_store_profit,
  SUM(web_net_profit)                       AS total_web_profit,
  SUM(store_return_loss)                    AS total_store_return_loss,
  SUM(web_return_loss)                      AS total_web_return_loss,
  SUM(inv_quantity_on_hand)                 AS total_inventory_qty,
  (SUM(store_net_profit) + SUM(web_net_profit) - SUM(store_return_loss) - SUM(web_return_loss)) AS total_net_profit,
  RANK() OVER (PARTITION BY s_store_name ORDER BY (SUM(store_net_profit) + SUM(web_net_profit) - SUM(store_return_loss) - SUM(web_return_loss)) DESC) AS profit_rank_per_store
FROM joined_data
GROUP BY
  s_store_name,
  s_state,
  ss_sold_date_sk,
  i_item_id,
  i_product_name
ORDER BY profit_rank_per_store, total_net_profit DESC
LIMIT 100
