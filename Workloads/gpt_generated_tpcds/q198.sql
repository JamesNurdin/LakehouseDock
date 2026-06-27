WITH aggregated AS (
    SELECT
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(p.p_cost) AS avg_promo_cost,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_brand, i.i_category, p.p_promo_name
)
SELECT
    i_brand,
    i_category,
    p_promo_name,
    total_return_qty,
    total_return_amt,
    avg_promo_cost,
    total_net_loss,
    return_count,
    ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_return_amt DESC) AS brand_promo_rank
FROM aggregated
ORDER BY total_return_amt DESC
LIMIT 50
