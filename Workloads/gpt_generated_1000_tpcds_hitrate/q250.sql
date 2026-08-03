WITH recent_promos AS (
    SELECT
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_cost,
        p.p_item_sk
    FROM promotion p
    WHERE p.p_start_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
      AND p.p_cost > (SELECT MIN(p_cost) FROM promotion WHERE p_promo_id = 'AAAAAAAADBAAAAAA')
)
SELECT
    dd.d_year,
    dd.d_month_seq,
    COUNT(DISTINCT inv.inv_item_sk) AS distinct_items,
    SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
    AVG(rp.p_cost) AS avg_promo_cost,
    MAX(rp.p_cost) AS max_promo_cost,
    MIN(rp.p_cost) AS min_promo_cost
FROM inventory inv
JOIN date_dim dd
    ON inv.inv_date_sk = dd.d_date_sk
JOIN recent_promos rp
    ON rp.p_start_date_sk = dd.d_date_sk
WHERE dd.d_dow IN (1, 3, 6)
  AND dd.d_current_year = 'Y'
  AND inv.inv_quantity_on_hand > (SELECT AVG(inv2.inv_quantity_on_hand) FROM inventory inv2)
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = inv.inv_item_sk
          AND p2.p_end_date_sk = dd.d_date_sk
          AND p2.p_cost > 500
    )
GROUP BY dd.d_year, dd.d_month_seq
ORDER BY total_qty_on_hand DESC
LIMIT 100
