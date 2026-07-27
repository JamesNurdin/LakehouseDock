WITH agg AS (
    SELECT
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        ws_site.web_name AS web_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH'
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        CONCAT(ws_site.web_name, '-', i.i_item_id) AS site_item_key,
        COUNT(DISTINCT sm.sm_ship_mode_id) AS distinct_ship_modes,
        REGEXP_EXTRACT(i.i_item_desc, '(\\w+) large', 1) AS extracted_word
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(i.i_item_desc, 'large')
      AND i.i_item_id LIKE 'A%'
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
          SELECT 1 FROM store_sales ss
          WHERE ss.ss_item_sk = i.i_item_sk
            AND ss.ss_net_profit > 0
      )
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        ws_site.web_name,
        REGEXP_EXTRACT(i.i_item_desc, '(\\w+) large', 1)
)
SELECT
    DISTINCT agg.i_item_id,
    agg.i_product_name,
    agg.web_name,
    agg.total_quantity,
    agg.total_profit,
    agg.profit_category,
    ROW_NUMBER() OVER (ORDER BY agg.total_profit DESC) AS profit_rank,
    agg.site_item_key,
    agg.distinct_ship_modes,
    agg.extracted_word,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_global_profit
FROM agg
ORDER BY profit_rank
LIMIT 100
