WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
promotion_agg AS (
    SELECT
        p_item_sk,
        SUM(p_cost) AS total_promo_cost,
        COUNT(*) AS promo_count
    FROM promotion
    GROUP BY p_item_sk
),
returns_agg AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_current_price,
    COALESCE(inv.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    COALESCE(ret.total_return_qty, 0) AS total_return_qty,
    COALESCE(ret.total_return_amt, 0) AS total_return_amt,
    COALESCE(promo.total_promo_cost, 0) AS total_promo_cost,
    CASE
        WHEN COALESCE(inv.total_quantity_on_hand, 0) = 0 THEN NULL
        ELSE COALESCE(ret.total_return_qty, 0) * 1.0 / inv.total_quantity_on_hand
    END AS return_quantity_ratio,
    CASE
        WHEN COALESCE(ret.total_return_qty, 0) = 0 THEN 0
        ELSE COALESCE(ret.total_return_amt, 0) / ret.total_return_qty
    END AS avg_return_amount_per_qty
FROM item i
LEFT JOIN inventory_agg inv
    ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN returns_agg ret
    ON ret.sr_item_sk = i.i_item_sk
LEFT JOIN promotion_agg promo
    ON promo.p_item_sk = i.i_item_sk
WHERE i.i_current_price > 0
ORDER BY total_return_amt DESC
LIMIT 100
