WITH returns_agg AS (
    SELECT
        cr.cr_item_sk AS cr_item_sk,
        cr.cr_ship_mode_sk AS cr_ship_mode_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 50.00
      AND cr.cr_reversed_charge < 200.00
      AND cr.cr_return_quantity > 0
    GROUP BY cr.cr_item_sk, cr.cr_ship_mode_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    sm.sm_type,
    p.p_promo_name,
    ra.total_net_loss,
    ra.total_return_qty,
    ra.total_return_amount,
    RANK() OVER (PARTITION BY sm.sm_type ORDER BY ra.total_net_loss DESC) AS net_loss_rank
FROM returns_agg ra
JOIN item i
    ON ra.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON i.i_item_sk = p.p_item_sk
WHERE p.p_channel_dmail = 'Y'
  AND i.i_wholesale_cost < 5.00
  AND p.p_purpose <> 'Unknown'
ORDER BY sm.sm_type, net_loss_rank
LIMIT 100
