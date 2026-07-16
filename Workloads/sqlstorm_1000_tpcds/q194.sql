WITH all_sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_quantity AS quantity,
           cs.cs_order_number AS order_number,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity,
           ss.ss_ticket_number AS order_number,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_quantity AS quantity,
           ws.ws_order_number AS order_number,
           'web' AS channel
    FROM web_sales ws
)
SELECT d.d_year,
       i.i_category,
       s.channel,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_net_profit,
       SUM(s.quantity) AS total_quantity,
       COUNT(DISTINCT s.order_number) AS distinct_orders
FROM all_sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year, i.i_category, s.channel
ORDER BY d.d_year ASC, total_net_paid DESC
LIMIT 200
