SELECT d_year,
       d_month,
       category,
       sum(total_profit) AS profit
FROM (
    SELECT d.d_year AS d_year,
           d.d_month_seq AS d_month,
           i.i_category AS category,
           ss.ss_net_profit AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           cs.cs_net_profit AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ws.ws_net_profit AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
) t
GROUP BY d_year, d_month, category
ORDER BY profit DESC
LIMIT 50
