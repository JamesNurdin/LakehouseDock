SELECT
  store_name,
  state,
  category,
  units,
  total_return_loss,
  total_net_profit,
  loss_rank,
  profit_rank
FROM (
  SELECT
    s.s_store_name AS store_name,
    s.s_state AS state,
    i.i_category AS category,
    i.i_units AS units,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_profit) AS total_net_profit,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE
    r.r_reason_desc LIKE '%damaged%'
    AND i.i_units IN ('Lb', 'Gram')
    AND i.i_current_price BETWEEN 10 AND 100
    AND cd.cd_purchase_estimate >= 8000
    AND s.s_state = 'CA'
    AND w.w_state = 'CA'
    AND sr.sr_return_quantity > 0
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
  GROUP BY
    s.s_store_name,
    s.s_state,
    i.i_category,
    i.i_units
) sub
ORDER BY total_return_loss DESC, profit_rank
LIMIT 100
