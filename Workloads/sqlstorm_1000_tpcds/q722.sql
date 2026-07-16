WITH sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_order_number AS order_number,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk AS date_sk,
           ss_ticket_number AS order_number,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_order_number AS order_number,
           ws_item_sk AS item_sk,
           ws_quantity AS quantity,
           ws_net_profit AS net_profit,
           'web' AS channel
    FROM web_sales
),
returns AS (
    SELECT cr_returned_date_sk AS date_sk,
           cr_order_number AS order_number,
           cr_item_sk AS item_sk,
           cr_return_quantity AS quantity,
           cr_net_loss AS net_loss,
           'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk AS date_sk,
           sr_ticket_number AS order_number,
           sr_item_sk AS item_sk,
           sr_return_quantity AS quantity,
           sr_net_loss AS net_loss,
           'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk AS date_sk,
           wr_order_number AS order_number,
           wr_item_sk AS item_sk,
           wr_return_quantity AS quantity,
           wr_net_loss AS net_loss,
           'web' AS channel
    FROM web_returns
)
SELECT d.d_year,
       i.i_category,
       s.channel,
       SUM(s.net_profit) AS total_profit,
       SUM(COALESCE(r.net_loss, 0)) AS total_loss,
       SUM(s.net_profit) - SUM(COALESCE(r.net_loss, 0)) AS net_gain,
       COUNT(DISTINCT s.order_number) AS orders,
       SUM(s.quantity) AS total_quantity_sold,
       SUM(COALESCE(r.quantity, 0)) AS total_quantity_returned
FROM sales s
LEFT JOIN returns r
  ON s.order_number = r.order_number
 AND s.item_sk = r.item_sk
 AND s.channel = r.channel
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
GROUP BY d.d_year, i.i_category, s.channel
ORDER BY d.d_year DESC, i.i_category, s.channel
LIMIT 100
