WITH sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        CASE WHEN MAX(p.p_discount_active) = 'Y' THEN 'Active' ELSE 'Inactive' END AS status_flag
    FROM catalog_sales cs
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND i.i_category_id = 2
    GROUP BY i.i_item_id, i.i_product_name
),
returns AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_return_amount) AS total_amount,
        CASE WHEN SUM(cr.cr_return_quantity) > 5 THEN 'HighQty' ELSE 'LowQty' END AS status_flag
    FROM catalog_returns cr
    INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_category_id = 2
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT
    s.i_item_id,
    s.i_product_name,
    'sales'   AS record_type,
    s.total_amount,
    s.status_flag
FROM sales s
UNION ALL
SELECT
    r.i_item_id,
    r.i_product_name,
    'returns' AS record_type,
    r.total_amount,
    r.status_flag
FROM returns r
LIMIT 100
