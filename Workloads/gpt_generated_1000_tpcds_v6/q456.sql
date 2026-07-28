WITH
  base AS (
    SELECT
      i.i_item_id,
      i.i_category,
      i.i_manufact,
      ca_bill.ca_state AS bill_state,
      ca_ship.ca_state AS ship_state,
      t_ws.t_hour AS sale_hour,
      ws.ws_net_profit,
      cr.cr_net_loss,
      wr.wr_net_loss,
      i.i_item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    WHERE i.i_category_id IN (2, 5, 9)
      AND t_ws.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_wholesale_cost > 3000
      AND NOT EXISTS (
        SELECT DISTINCT cr_bad.cr_item_sk
        FROM catalog_returns cr_bad
        WHERE cr_bad.cr_item_sk = i.i_item_sk
          AND cr_bad.cr_return_quantity > 5
      )
  ),
  agg AS (
    SELECT
      i_item_id,
      i_category,
      i_manufact,
      bill_state,
      ship_state,
      sale_hour,
      SUM(ws_net_profit) AS total_profit,
      SUM(cr_net_loss) AS total_catalog_loss,
      SUM(wr_net_loss) AS total_web_return_loss
    FROM base
    GROUP BY
      i_item_id,
      i_category,
      i_manufact,
      bill_state,
      ship_state,
      sale_hour
  )
SELECT
  i_item_id,
  i_category,
  i_manufact,
  bill_state,
  ship_state,
  sale_hour,
  total_profit,
  total_catalog_loss,
  total_web_return_loss,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
