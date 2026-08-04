WITH base AS (
  SELECT
    i.i_item_id,
    i.i_category_id,
    i.i_formulation,
    cs.cs_net_profit,
    ws.ws_net_profit,
    ss.ss_net_profit,
    wr.wr_net_loss,
    p.p_promo_name,
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name,
    r.r_reason_desc,
    td.t_hour,
    we.web_state
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = td.t_time_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE i.i_category_id = 5
    AND i.i_formulation LIKE '%steel%'
    AND p.p_channel_press = 'N'
    AND td.t_hour BETWEEN 8 AND 12
    AND we.web_state = 'CA'
),
ranked AS (
  SELECT
    i_item_id,
    i_category_id,
    i_formulation,
    (COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0) + COALESCE(ss_net_profit, 0) - COALESCE(wr_net_loss, 0)) AS total_net_profit,
    RANK() OVER (PARTITION BY i_category_id ORDER BY (COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0) + COALESCE(ss_net_profit, 0) - COALESCE(wr_net_loss, 0)) DESC) AS profit_rank
  FROM base
),
high AS (
  SELECT i_item_id, total_net_profit, profit_rank
  FROM ranked
  WHERE total_net_profit > 2000
),
moderate AS (
  SELECT i_item_id, total_net_profit, profit_rank
  FROM ranked
  WHERE total_net_profit BETWEEN 1000 AND 2000
)
SELECT h.i_item_id, h.total_net_profit, h.profit_rank
FROM high h
EXCEPT
SELECT m.i_item_id, m.total_net_profit, m.profit_rank
FROM moderate m
ORDER BY total_net_profit DESC
LIMIT 100
