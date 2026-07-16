SELECT d.d_year,
       i.i_item_id,
       i.i_item_desc,
       SUM(s.net_profit) AS total_net_profit,
       SUM(s.sales_price * s.quantity) AS total_sales_amount
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_sales_price AS sales_price,
           cs.cs_quantity AS quantity
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           ss.ss_sales_price,
           ss.ss_quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           ws.ws_sales_price,
           ws.ws_quantity
    FROM web_sales ws
) s
JOIN date_dim d ON d.d_date_sk = s.date_sk
JOIN item i ON i.i_item_sk = s.item_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, i.i_item_id, i.i_item_desc
ORDER BY total_net_profit DESC
LIMIT 10
