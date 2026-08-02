WITH high_price_items AS (
    SELECT i_item_sk,
           i_category,
           i_current_price
    FROM item
    TABLESAMPLE BERNOULLI (5)
    WHERE i_current_price > 100
)
SELECT agg.i_category,
       agg.total_sales,
       agg.total_quantity,
       agg.total_net_profit,
       agg.profit_flag,
       agg.sales_channel
FROM (
    SELECT hpi.i_category AS i_category,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_net_profit) AS total_net_profit,
           CASE WHEN SUM(ss.ss_net_profit) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
           'STORE' AS sales_channel
    FROM store_sales ss
    JOIN high_price_items hpi
      ON ss.ss_item_sk = hpi.i_item_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY hpi.i_category

    UNION ALL

    SELECT hpi.i_category AS i_category,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_net_profit,
           CASE WHEN SUM(ws.ws_net_profit) > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
           'WEB' AS sales_channel
    FROM web_sales ws
    JOIN high_price_items hpi
      ON ws.ws_item_sk = hpi.i_item_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY hpi.i_category
) AS agg
ORDER BY agg.total_net_profit DESC
LIMIT 100
