WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_current_price
    FROM   item
    WHERE  i_current_price > 100
)
SELECT  fi.i_item_sk,
        fi.i_product_name,
        'store' AS sales_channel,
        ss_agg.total_quantity,
        ss_agg.total_net_profit,
        (
            SELECT AVG(ss2.ss_net_profit)
            FROM   store_sales ss2
            WHERE  ss2.ss_item_sk = fi.i_item_sk
        ) AS avg_store_net_profit
FROM    filtered_items fi
JOIN (
        SELECT ss_item_sk,
               SUM(ss_quantity)      AS total_quantity,
               SUM(ss_net_profit)    AS total_net_profit
        FROM   store_sales
        WHERE  ss_ext_wholesale_cost > 5000
        GROUP BY ss_item_sk
     ) ss_agg
     ON ss_agg.ss_item_sk = fi.i_item_sk
WHERE EXISTS (
        SELECT 1
        FROM   catalog_sales cs
        WHERE  cs.cs_item_sk = fi.i_item_sk
          AND  cs.cs_net_profit > 500
    )
UNION ALL
SELECT  fi.i_item_sk,
        fi.i_product_name,
        'web' AS sales_channel,
        ws_agg.total_quantity,
        ws_agg.total_net_profit,
        (
            SELECT AVG(ws2.ws_net_profit)
            FROM   web_sales ws2
            WHERE  ws2.ws_item_sk = fi.i_item_sk
        ) AS avg_web_net_profit
FROM    filtered_items fi
JOIN (
        SELECT ws_item_sk,
               SUM(ws_quantity)      AS total_quantity,
               SUM(ws_net_profit)    AS total_net_profit
        FROM   web_sales
        WHERE  ws_ext_wholesale_cost > 5000
          AND  ws_web_page_sk IN (
                 SELECT wp_web_page_sk
                 FROM   web_page
                 WHERE  wp_type = 'home'
                   AND  wp_creation_date_sk = 2450800
               )
        GROUP BY ws_item_sk
     ) ws_agg
     ON ws_agg.ws_item_sk = fi.i_item_sk
ORDER BY total_net_profit DESC
LIMIT 100
