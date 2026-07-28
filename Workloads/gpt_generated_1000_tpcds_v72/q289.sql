WITH store_agg AS (
    SELECT i.i_brand AS brand,
           i.i_category AS category,
           SUM(ss.ss_net_profit) AS total_net_profit,
           'store' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE i.i_manufact_id = 220
      AND td.t_hour BETWEEN 6 AND 12
      AND c.c_birth_country = 'MONACO'
    GROUP BY i.i_brand, i.i_category
),
web_agg AS (
    SELECT i.i_brand AS brand,
           i.i_category AS category,
           SUM(ws.ws_net_profit) AS total_net_profit,
           'web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_manufact_id = 220
      AND td.t_hour BETWEEN 13 AND 23
      AND ws.ws_coupon_amt > 1000
    GROUP BY i.i_brand, i.i_category
)
SELECT brand,
       category,
       total_net_profit,
       channel
FROM store_agg
UNION ALL
SELECT brand,
       category,
       total_net_profit,
       channel
FROM web_agg
ORDER BY total_net_profit DESC
LIMIT 100
