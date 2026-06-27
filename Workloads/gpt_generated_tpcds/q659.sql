WITH sales_agg AS (
    SELECT
        i.i_category,
        p.p_promo_name,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_quantity) AS total_qty_sold,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY i.i_category, p.p_promo_name
),
returns_agg AS (
    SELECT
        i.i_category,
        p.p_promo_name,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_qty_returned
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    GROUP BY i.i_category, p.p_promo_name
)
SELECT
    s.i_category,
    s.p_promo_name,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    s.total_qty_sold,
    COALESCE(r.total_qty_returned, 0) AS total_qty_returned,
    CASE WHEN s.total_qty_sold > 0 THEN s.total_discount_amount / s.total_qty_sold ELSE 0 END AS avg_discount_per_item,
    RANK() OVER (ORDER BY s.total_sales_profit - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
    AND s.p_promo_name = r.p_promo_name
ORDER BY net_profit_after_returns DESC
LIMIT 10
