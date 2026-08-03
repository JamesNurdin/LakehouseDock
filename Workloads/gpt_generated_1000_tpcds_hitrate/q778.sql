WITH
  -- Store channel with returns and reasons
  store_cte AS (
    SELECT
      ss.ss_ticket_number            AS ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_store_sk,
      ss.ss_quantity,
      ss.ss_net_profit,
      s.s_store_name,
      d_sold.d_year,
      t_sold.t_hour,
      sr.sr_return_quantity,
      r_sr.r_reason_desc            AS return_reason,
      d_ret.d_year                  AS return_year,
      t_ret.t_hour                  AS return_hour,
      'store'                       AS channel
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ss.ss_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN date_dim d_ret
      ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret
      ON sr.sr_return_time_sk = t_ret.t_time_sk
  ),
  -- Catalog channel with returns and reasons
  catalog_cte AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_net_profit,
      d_sold.d_year,
      t_sold.t_hour,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      cr.cr_return_quantity,
      r_cr.r_reason_desc            AS return_reason,
      d_ret.d_year                  AS return_year,
      t_ret.t_hour                  AS return_hour,
      'catalog'                     AS channel
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret
      ON cr.cr_returned_time_sk = t_ret.t_time_sk
  ),
  -- Web channel with returns and reasons
  web_cte AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_ship_date_sk,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk,
      ws.ws_ship_mode_sk,
      ws.ws_warehouse_sk,
      ws.ws_net_profit,
      d_sold.d_year,
      t_sold.t_hour,
      wp.wp_url,
      web.web_name,
      sm.sm_type,
      w.w_warehouse_name,
      wr.wr_return_quantity,
      r_wr.r_reason_desc            AS return_reason,
      d_ret.d_year                  AS return_year,
      t_ret.t_hour                  AS return_hour,
      'web'                         AS channel
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
      ON ws.ws_web_site_sk = web.web_site_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret
      ON wr.wr_returned_time_sk = t_ret.t_time_sk
  ),
  -- Union all channels into a single stream
  combined AS (
    SELECT
      ticket_number                AS key,
      channel,
      s_store_name                AS entity_name,
      d_year,
      t_hour,
      ss_quantity                 AS quantity,
      ss_net_profit               AS net_profit,
      return_reason,
      return_year,
      return_hour
    FROM store_cte
    UNION ALL
    SELECT
      cs_order_number             AS key,
      channel,
      cc_name                     AS entity_name,
      d_year,
      t_hour,
      NULL                        AS quantity,
      cs_net_profit               AS net_profit,
      return_reason,
      return_year,
      return_hour
    FROM catalog_cte
    UNION ALL
    SELECT
      ws_order_number             AS key,
      channel,
      web_name                    AS entity_name,
      d_year,
      t_hour,
      NULL                        AS quantity,
      ws_net_profit               AS net_profit,
      return_reason,
      return_year,
      return_hour
    FROM web_cte
  )
SELECT
  channel,
  CASE WHEN SUM(net_profit) > (SELECT MAX(cs.cs_net_profit) FROM catalog_sales cs)
       THEN 'Above Max'
       ELSE 'Below Max'
  END                                                    AS profit_vs_max,
  SUM(net_profit)                                         AS total_profit,
  COUNT(*)                                                AS txn_count,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY SUM(net_profit) DESC) AS rn,
  (
    SELECT COUNT(*)
    FROM (
      SELECT cs_order_number FROM catalog_sales cs WHERE cs.cs_net_profit > 0
      INTERSECT
      SELECT ws_order_number FROM web_sales ws WHERE ws.ws_net_profit > 0
    ) intersect_sub
  )                                                      AS intersect_pos_orders,
  (
    SELECT COUNT(*)
    FROM (
      SELECT cs_order_number FROM catalog_sales cs WHERE cs.cs_net_profit > 0
      EXCEPT
      SELECT ws_order_number FROM web_sales ws WHERE ws.ws_net_profit > 0
    ) except_sub
  )                                                      AS catalog_only_pos_orders
FROM combined
GROUP BY channel
ORDER BY total_profit DESC
