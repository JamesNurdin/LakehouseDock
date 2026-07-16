SELECT d_year,
       i_category,
       i_brand,
       SUM(total_net_paid) AS total_sales,
       SUM(total_net_profit) AS total_profit
FROM (
    SELECT d.d_year,
           i.i_category,
           i.i_brand,
           cs.cs_net_paid AS total_net_paid,
           cs.cs_net_profit AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           i.i_category,
           i.i_brand,
           ws.ws_net_paid AS total_net_paid,
           ws.ws_net_profit AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           i.i_category,
           i.i_brand,
           ss.ss_net_paid AS total_net_paid,
           ss.ss_net_profit AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
) t
GROUP BY d_year, i_category, i_brand
ORDER BY d_year, i_category, i_brand
