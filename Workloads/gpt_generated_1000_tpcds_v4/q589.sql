WITH returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        cr.cr_return_amount AS amount,
        cr.cr_return_quantity,
        'return' AS src
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 0
      AND sm.sm_type = 'AIR'
),
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        ws.ws_ext_sales_price AS amount,
        ws.ws_quantity,
        'sale' AS src
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_ext_sales_price > 1000
      AND ws_site.web_country = 'United States'
)
SELECT
    comb.i_item_id,
    comb.i_product_name,
    comb.src,
    comb.amount,
    ROW_NUMBER() OVER (PARTITION BY comb.src ORDER BY comb.amount DESC) AS rank_by_src
FROM (
    SELECT i_item_id, i_product_name, amount, src FROM returns_agg
    UNION ALL
    SELECT i_item_id, i_product_name, amount, src FROM sales_agg
) AS comb
ORDER BY comb.src, rank_by_src
LIMIT 100
