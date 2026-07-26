WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
returns_agg AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    COALESCE(s.total_quantity_sold, 0) AS qty_sold,
    COALESCE(r.total_return_quantity, 0) AS qty_returned,
    COALESCE(s.total_quantity_sold, 0) - COALESCE(r.total_return_quantity, 0) AS net_quantity,
    COALESCE(s.total_net_profit, 0) AS sales_profit,
    COALESCE(r.total_return_loss, 0) AS return_loss,
    COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit,
    CASE
        WHEN COALESCE(s.total_quantity_sold, 0) - COALESCE(r.total_return_quantity, 0) < 0 THEN 'Return > Sale'
        ELSE 'OK'
    END AS quantity_status,
    RANK() OVER (PARTITION BY i.i_category ORDER BY COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank_in_category,
    SUM(COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY i.i_category ORDER BY i.i_item_id ROWS UNBOUNDED PRECEDING) AS cumulative_profit_by_category,
    CASE
        WHEN (SELECT MAX(p.p_discount_active) FROM promotion p WHERE p.p_item_sk = i.i_item_sk) = 'Y' THEN 'Promotion Active'
        ELSE 'No Promotion'
    END AS promo_status
FROM item i
LEFT JOIN sales_agg s
    ON i.i_item_sk = s.cs_item_sk
LEFT JOIN returns_agg r
    ON i.i_item_sk = r.sr_item_sk
WHERE i.i_category IS NOT NULL
ORDER BY i.i_category, profit_rank_in_category
LIMIT 100
