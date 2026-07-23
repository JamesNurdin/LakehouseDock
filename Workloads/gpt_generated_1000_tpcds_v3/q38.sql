WITH item_sales AS (
    SELECT
        i.i_item_sk AS i_item_sk,
        i.i_item_id AS i_item_id,
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_time_sk = td.t_time_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE i.i_current_price > 20.00
      AND i.i_wholesale_cost BETWEEN 0.5 AND 30.0
      AND td.t_am_pm = 'PM'
      AND td.t_minute >= 5
      AND ws.ws_net_paid_inc_ship > 100.0
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, i.i_category
)
SELECT
    i_brand,
    i_category,
    i_item_id,
    total_sales,
    total_profit,
    total_store_return_loss,
    total_web_return_loss,
    orders_cnt,
    avg_quantity,
    (total_profit / (SELECT AVG(total_profit) FROM item_sales)) AS profit_to_avg_ratio,
    (SELECT COUNT(DISTINCT ws2.ws_order_number) FROM web_sales ws2 WHERE ws2.ws_item_sk = i_item_sk) AS distinct_orders_for_item
FROM item_sales
WHERE total_profit > (SELECT AVG(total_profit) FROM item_sales)
ORDER BY profit_to_avg_ratio DESC
LIMIT 100
