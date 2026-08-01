WITH sales AS (
  SELECT
    s.s_store_name,
    d.d_year,
    sm.sm_type,
    ss.ss_ticket_number,
    ss.ss_net_profit,
    ws.ws_net_profit,
    wr.wr_net_loss,
    ss.ss_item_sk,
    ss.ss_sold_date_sk,
    ws.ws_list_price
  FROM store_sales ss
  JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s                  ON ss.ss_store_sk   = s.s_store_sk
  JOIN date_dim d_closed        ON s.s_closed_date_sk = d_closed.d_date_sk
  JOIN web_sales ws            ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_returns wr          ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_item_sk       = ws.ws_item_sk
  JOIN date_dim d_ret          ON wr.wr_returned_date_sk = d_ret.d_date_sk
  WHERE d.d_year = 2002
    AND s.s_state = 'TX'
    AND sm.sm_type = 'AIR'
    AND ws.ws_list_price > 150
    AND EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.inv_item_sk = ss.ss_item_sk
            AND i.inv_date_sk = ss.ss_sold_date_sk
            AND i.inv_quantity_on_hand > 500
        )
)
SELECT
  s_store_name,
  d_year,
  sm_type,
  COUNT(DISTINCT ss_ticket_number)                         AS sales_transactions,
  SUM(ss_net_profit)                                      AS total_store_profit,
  SUM(ws_net_profit)                                      AS total_web_profit,
  SUM(wr_net_loss)                                        AS total_return_loss,
  AVG(
      (SELECT COALESCE(SUM(i2.inv_quantity_on_hand), 0)
       FROM inventory i2
       WHERE i2.inv_item_sk = ss_item_sk
         AND i2.inv_date_sk = ss_sold_date_sk)
  )                                                       AS avg_inventory_quantity
FROM sales
GROUP BY s_store_name, d_year, sm_type
HAVING SUM(ss_net_profit) > 10000
ORDER BY total_store_profit DESC
LIMIT 100
