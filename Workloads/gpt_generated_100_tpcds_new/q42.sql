WITH
    cat_agg AS (
        SELECT
            i.i_item_sk,
            SUM(cs.cs_net_paid) AS cat_sales,
            COUNT(*) AS cat_orders,
            MAX(cs.cs_sold_date_sk) AS latest_sold_date_sk
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, '(?i)special')
          AND i.i_brand LIKE 'Brand%'
        GROUP BY i.i_item_sk
    ),
    web_agg AS (
        SELECT
            i.i_item_sk,
            SUM(ws.ws_net_paid) AS web_sales,
            COUNT(*) AS web_orders
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE regexp_like(i.i_item_desc, '(?i)premium')
          AND i.i_color LIKE 'Red%'
        GROUP BY i.i_item_sk
    ),
    intersect_items AS (
        SELECT i_item_sk FROM cat_agg
        INTERSECT
        SELECT i_item_sk FROM web_agg
    ),
    final AS (
        SELECT
            i.i_item_id,
            i.i_item_desc,
            concat(i.i_brand, ' - ', i.i_product_name) AS brand_product,
            regexp_extract(i.i_item_desc, '(\\w+)\\s+(\\w+)', 2) AS extracted_word,
            cat.cat_sales,
            web.web_sales,
            (cat.cat_sales + web.web_sales) AS total_sales
        FROM intersect_items ii
        JOIN item i ON ii.i_item_sk = i.i_item_sk
        JOIN cat_agg cat ON i.i_item_sk = cat.i_item_sk
        JOIN web_agg web ON i.i_item_sk = web.i_item_sk
        WHERE NOT EXISTS (
            SELECT 1 FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
        )
    )
SELECT
    i_item_id AS item_id,
    i_item_desc AS item_desc,
    brand_product,
    extracted_word,
    cat_sales,
    web_sales,
    total_sales
FROM final
ORDER BY total_sales DESC
LIMIT 100
