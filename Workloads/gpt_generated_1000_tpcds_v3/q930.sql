WITH sales_agg AS (
    SELECT cs_item_sk AS item_sk, SUM(cs_net_profit) AS net_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
    UNION ALL
    SELECT ws_item_sk AS item_sk, SUM(ws_net_profit) AS net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
item_profit AS (
    SELECT item_sk, SUM(net_profit) AS total_net_profit
    FROM sales_agg
    GROUP BY item_sk
),
returns_filtered AS (
    SELECT DISTINCT sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_manager LIKE 'John%'
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    ip.total_net_profit,
    CONCAT(i.i_brand, ' - ', SUBSTRING(i.i_item_desc, 1, 10)) AS brand_short_desc,
    REGEXP_EXTRACT(i.i_item_desc, '(?i)(WOOD|METAL|PLASTIC)', 1) AS extracted_material,
    SUBSTRING(i.i_item_desc, 1, 10) AS short_desc
FROM item i
JOIN item_profit ip ON i.i_item_sk = ip.item_sk
JOIN returns_filtered rf ON i.i_item_sk = rf.item_sk
WHERE REGEXP_LIKE(i.i_item_desc, '(?i)WOOD')
  AND i.i_product_name LIKE 'Premium%'
  AND ip.total_net_profit > (SELECT AVG(total_net_profit) FROM item_profit)
ORDER BY ip.total_net_profit DESC
LIMIT 10
