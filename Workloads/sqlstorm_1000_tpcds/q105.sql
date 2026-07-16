WITH item_strings AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        i_category,
        i_color,
        lower(regexp_replace(i_item_desc, '[^a-z0-9 ]', '')) AS clean_desc,
        cardinality(split(lower(regexp_replace(i_item_desc, '[^a-z0-9 ]', '')), ' ')) AS desc_word_count,
        length(i_item_desc) AS raw_desc_len
    FROM item
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk,
        sum(cs.cs_ext_sales_price) AS total_catalog_sales,
        sum(cs.cs_quantity) AS total_catalog_qty,
        sum(cs.cs_net_profit) AS net_profit_catalog
    FROM catalog_sales cs
    JOIN item_strings i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cs.cs_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk,
        sum(ws.ws_ext_sales_price) AS total_web_sales,
        sum(ws.ws_quantity) AS total_web_qty,
        sum(ws.ws_net_profit) AS net_profit_web
    FROM web_sales ws
    JOIN item_strings i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk
),
store_sales_agg AS (
    SELECT
        ss.ss_item_sk,
        sum(ss.ss_ext_sales_price) AS total_store_sales,
        sum(ss.ss_quantity) AS total_store_qty,
        sum(ss.ss_net_profit) AS net_profit_store
    FROM store_sales ss
    JOIN item_strings i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_item_sk
),
promo_agg AS (
    SELECT
        p_item_sk,
        array_join(array_agg(lower(p.p_promo_name)), ', ') AS promo_names
    FROM promotion p
    GROUP BY p_item_sk
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_color,
    i.clean_desc,
    i.desc_word_count,
    i.raw_desc_len,
    ca.total_catalog_sales,
    ca.total_catalog_qty,
    ca.net_profit_catalog,
    wa.total_web_sales,
    wa.total_web_qty,
    wa.net_profit_web,
    sa.total_store_sales,
    sa.total_store_qty,
    sa.net_profit_store,
    pa.promo_names,
    concat_ws(' | ',
        concat('Item:', i.i_product_name),
        concat('DescWords:', CAST(i.desc_word_count AS VARCHAR)),
        concat('CatSales:', coalesce(CAST(ca.total_catalog_sales AS VARCHAR), '0')),
        concat('WebSales:', coalesce(CAST(wa.total_web_sales AS VARCHAR), '0')),
        concat('StoreSales:', coalesce(CAST(sa.total_store_sales AS VARCHAR), '0')),
        concat('Promos:', coalesce(pa.promo_names, 'none'))
    ) AS debug_string
FROM item_strings i
LEFT JOIN catalog_sales_agg ca ON i.i_item_sk = ca.cs_item_sk
LEFT JOIN web_sales_agg wa ON i.i_item_sk = wa.ws_item_sk
LEFT JOIN store_sales_agg sa ON i.i_item_sk = sa.ss_item_sk
LEFT JOIN promo_agg pa ON i.i_item_sk = pa.p_item_sk
WHERE i.desc_word_count > 5
ORDER BY i.desc_word_count DESC, ca.total_catalog_sales DESC
LIMIT 100
