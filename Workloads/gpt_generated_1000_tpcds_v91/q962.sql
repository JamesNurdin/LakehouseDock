WITH sampled_items AS (
    SELECT i_item_sk, i_item_id, i_category, i_current_price
    FROM tpcds.item
    TABLESAMPLE BERNOULLI (10)
),
store_high_profit_items AS (
    SELECT DISTINCT ss.ss_item_sk AS item_sk
    FROM tpcds.store_sales ss
    JOIN sampled_items si ON ss.ss_item_sk = si.i_item_sk
    JOIN tpcds.time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_net_profit > 1000
      AND td.t_hour BETWEEN 8 AND 20
      AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
),
web_high_profit_items AS (
    SELECT DISTINCT ws.ws_item_sk AS item_sk
    FROM tpcds.web_sales ws
    JOIN sampled_items si ON ws.ws_item_sk = si.i_item_sk
    JOIN tpcds.time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_net_profit > 1000
      AND td.t_hour BETWEEN 8 AND 20
      AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p
          WHERE p.p_promo_sk = ws.ws_promo_sk
            AND p.p_discount_active = 'Y'
      )
),
common_high_profit_items AS (
    SELECT item_sk FROM store_high_profit_items
    INTERSECT
    SELECT item_sk FROM web_high_profit_items
)
SELECT i.i_item_id,
       i.i_product_name,
       i.i_category,
       CASE
           WHEN ss_agg.total_net_profit > (
               SELECT avg(t.total_net_profit)
               FROM (
                   SELECT sum(ss2.ss_net_profit) AS total_net_profit
                   FROM tpcds.store_sales ss2
                   GROUP BY ss2.ss_item_sk
               ) t
           ) THEN 'Store Above Avg'
           WHEN ws_agg.total_net_profit > (
               SELECT avg(t.total_net_profit)
               FROM (
                   SELECT sum(ws2.ws_net_profit) AS total_net_profit
                   FROM tpcds.web_sales ws2
                   GROUP BY ws2.ws_item_sk
               ) t
           ) THEN 'Web Above Avg'
           ELSE 'Below Avg'
       END AS profit_category,
       ss_agg.total_net_profit,
       ws_agg.total_net_profit
FROM common_high_profit_items chi
JOIN tpcds.item i ON chi.item_sk = i.i_item_sk
LEFT JOIN (
    SELECT ss_item_sk, sum(ss_net_profit) AS total_net_profit
    FROM tpcds.store_sales
    GROUP BY ss_item_sk
) ss_agg ON i.i_item_sk = ss_agg.ss_item_sk
LEFT JOIN (
    SELECT ws_item_sk, sum(ws_net_profit) AS total_net_profit
    FROM tpcds.web_sales
    GROUP BY ws_item_sk
) ws_agg ON i.i_item_sk = ws_agg.ws_item_sk
WHERE i.i_current_price >= 20
ORDER BY profit_category DESC, i.i_item_id
LIMIT 100
