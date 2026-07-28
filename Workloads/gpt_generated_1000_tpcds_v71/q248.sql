WITH filtered_items AS (
    SELECT i_item_sk,
           i_category,
           i_brand,
           i_current_price
    FROM   item
    WHERE  i_rec_end_date >= DATE '2000-01-01'
)
SELECT   sales_channel,
         category,
         total_sales,
         total_profit,
         profit_flag
FROM (
    SELECT   'Catalog' AS sales_channel,
             fi.i_category AS category,
             SUM(cs.cs_ext_sales_price) AS total_sales,
             SUM(cs.cs_net_profit) AS total_profit,
             CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM     catalog_sales cs
    JOIN     filtered_items fi
           ON cs.cs_item_sk = fi.i_item_sk
    JOIN     time_dim td
           ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE    td.t_hour BETWEEN 9 AND 17
    GROUP BY fi.i_category
    HAVING   SUM(cs.cs_ext_sales_price) > 10000

    UNION ALL

    SELECT   'Web' AS sales_channel,
             fi.i_category AS category,
             SUM(ws.ws_ext_sales_price) AS total_sales,
             SUM(ws.ws_net_profit) AS total_profit,
             CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM     web_sales ws
    JOIN     filtered_items fi
           ON ws.ws_item_sk = fi.i_item_sk
    JOIN     time_dim td
           ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE    td.t_hour BETWEEN 9 AND 17
    GROUP BY fi.i_category
    HAVING   SUM(ws.ws_ext_sales_price) > 10000
) AS combined
ORDER BY total_sales DESC
LIMIT 100
