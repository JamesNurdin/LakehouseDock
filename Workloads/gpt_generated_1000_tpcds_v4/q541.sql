WITH sales_agg AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)TV|Camera')
      AND p.p_promo_name LIKE '%DISCOUNT%'
    GROUP BY cp.cp_catalog_page_sk, cp.cp_catalog_page_id
),
returns_agg AS (
    SELECT
        cp.cp_catalog_page_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)TV|Camera')
    GROUP BY cp.cp_catalog_page_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    sa.total_sales_profit,
    ra.total_return_loss,
    sa.distinct_orders,
    ra.distinct_return_orders,
    (sa.total_sales_profit - ra.total_return_loss) AS net_contribution,
    CONCAT('Dept-', cp.cp_department) AS dept_label
FROM catalog_page cp
JOIN sales_agg sa ON cp.cp_catalog_page_sk = sa.cp_catalog_page_sk
JOIN returns_agg ra ON cp.cp_catalog_page_sk = ra.cp_catalog_page_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
      AND cr2.cr_return_amount > 1000
)
  AND cp.cp_description LIKE '%special%'
  AND sa.total_sales_profit > (
    SELECT AVG(total_sales_profit) FROM sales_agg
)
ORDER BY net_contribution DESC
LIMIT 100
