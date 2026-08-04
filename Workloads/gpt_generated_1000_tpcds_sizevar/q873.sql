WITH ws_items AS (
    SELECT DISTINCT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
      AND i.i_brand LIKE 'Brand%'
),
cr_items AS (
    SELECT DISTINCT cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
      AND i.i_category = 'Electronics'
),
intersect_items AS (
    SELECT item_sk FROM ws_items
    INTERSECT
    SELECT item_sk FROM cr_items
),
full_item_promo AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_item_desc,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_email
    FROM item i
    FULL OUTER JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    WHERE i.i_item_sk IN (SELECT item_sk FROM intersect_items)
       OR p.p_item_sk IN (SELECT item_sk FROM intersect_items)
),
agg_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_qty,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT *
FROM (
    SELECT
        fp.i_item_sk,
        fp.i_product_name,
        fp.i_category,
        fp.i_brand,
        CONCAT(fp.i_product_name, ' - ', COALESCE(fp.p_promo_name, 'No Promo')) AS product_promo,
        SUBSTRING(fp.i_item_desc FROM 1 FOR 20) AS short_desc,
        regexp_extract(fp.i_item_desc, '(\\d+)', 1) AS first_number,
        fp.p_promo_id,
        a.total_sales,
        a.total_qty,
        ROW_NUMBER() OVER (ORDER BY a.total_sales DESC NULLS LAST) AS global_row_num,
        ROW_NUMBER() OVER (PARTITION BY fp.i_category ORDER BY a.total_sales DESC NULLS LAST) AS cat_rank
    FROM full_item_promo fp
    LEFT JOIN agg_sales a
        ON fp.i_item_sk = a.ws_item_sk
) t
WHERE t.cat_rank <= 5
ORDER BY t.i_category, t.cat_rank, t.global_row_num
LIMIT 100
