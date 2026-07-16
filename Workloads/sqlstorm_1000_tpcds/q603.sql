SELECT d.d_year,
       d.d_month_seq,
       i.i_category,
       SUM(f.profit) AS total_profit
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit
    FROM web_sales ws
) f
JOIN date_dim d ON f.date_sk = d.d_date_sk
JOIN item i ON f.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, d.d_month_seq, i.i_category
ORDER BY total_profit DESC
LIMIT 100
