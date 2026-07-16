SELECT d.d_year,
       i.i_category,
       SUM(s.net_paid) AS total_net_paid,
       SUM(s.net_profit) AS total_net_profit
FROM (
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_paid,
           ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_paid,
           ws.ws_net_profit
    FROM web_sales ws
) s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category
