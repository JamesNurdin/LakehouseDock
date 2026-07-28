/* Goal: Identify the top 100 items (by profit) sold through catalog and web channels that had active promotions, sufficient quantity, and specific channel characteristics, combining the two sales channels with a UNION ALL. */
WITH catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit)      AS total_profit,
        COUNT(*)                  AS transaction_count
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 5
      AND p.p_discount_active = 'Y'
      AND EXISTS (
            SELECT 1
            FROM tpcds.catalog_page cp
            WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
              AND cp.cp_type = 'A'
        )
    GROUP BY i.i_item_id, i.i_product_name
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit)      AS total_profit,
        COUNT(*)                  AS transaction_count
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_quantity > 5
      AND p.p_discount_active = 'Y'
      AND EXISTS (
            SELECT 1
            FROM tpcds.ship_mode sm
            WHERE sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
              AND sm.sm_type = 'AIR'
        )
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT
    i_item_id,
    i_product_name,
    total_sales,
    total_profit,
    transaction_count
FROM catalog_agg
UNION ALL
SELECT
    i_item_id,
    i_product_name,
    total_sales,
    total_profit,
    transaction_count
FROM web_agg
ORDER BY total_profit DESC
LIMIT 100
