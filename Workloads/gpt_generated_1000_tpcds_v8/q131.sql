WITH catalog_agg AS (
    SELECT
        'catalog' AS channel,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_current_price,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_net_profit > 0
      AND w.w_state = 'CA'
    GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_current_price
),
web_agg AS (
    SELECT
        'web' AS channel,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_current_price,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_net_profit > 0
      AND w.w_state = 'CA'
    GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_current_price
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    channel,
    i_item_id,
    i_product_name,
    i_category,
    i_current_price,
    total_net_profit,
    orders_cnt,
    RANK() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS profit_rank,
    (
        SELECT COUNT(*)
        FROM item i2
        WHERE i2.i_category = combined.i_category
          AND i2.i_current_price > combined.i_current_price
    ) AS higher_price_items_in_category
FROM combined
WHERE total_net_profit > (
    SELECT AVG(c2.total_net_profit)
    FROM combined c2
    WHERE c2.channel = combined.channel
)
ORDER BY channel, profit_rank
LIMIT 100
