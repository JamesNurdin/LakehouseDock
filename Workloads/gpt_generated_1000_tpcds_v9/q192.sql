WITH sales_per_item AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_brand AS brand,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS full_desc,
        REGEXP_EXTRACT(i.i_product_name, '(\\d+)', 1) AS product_code,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND REGEXP_LIKE(i.i_product_name, '\\d{3}')
      AND i.i_color LIKE 'Red%'
    GROUP BY i.i_item_id, i.i_product_name, i.i_brand
),
returns_per_item AS (
    SELECT
        i.i_item_id AS item_id,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_store_credit) AS total_store_credit,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_count,
        MIN(r.r_reason_desc) AS sample_reason
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)damage')
    GROUP BY i.i_item_id
)
SELECT
    sp.full_desc,
    sp.product_code,
    sp.total_sales,
    sp.total_profit,
    COALESCE(rp.total_refunded_cash, 0) + COALESCE(rp.total_store_credit, 0) AS total_refunds,
    sp.total_profit - COALESCE(rp.total_net_loss, 0) AS profit_after_returns,
    CASE
        WHEN sp.total_profit - COALESCE(rp.total_net_loss, 0) > 5000 THEN 'High'
        WHEN sp.total_profit - COALESCE(rp.total_net_loss, 0) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_per_item sp
LEFT JOIN returns_per_item rp ON sp.item_id = rp.item_id
ORDER BY profit_after_returns DESC
LIMIT 100
