WITH filtered_cr AS (
    SELECT cr.cr_item_sk,
           cr.cr_returned_date_sk,
           cr.cr_net_loss,
           cr.cr_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND cr.cr_return_amount > 50
),
filtered_sr AS (
    SELECT sr.sr_item_sk,
           sr.sr_returned_date_sk,
           sr.sr_net_loss,
           sr.sr_return_amt_inc_tax
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND sr.sr_return_amt_inc_tax > 50
),
combined_returns AS (
    SELECT cr.cr_item_sk AS item_sk,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_net_loss AS net_loss
    FROM filtered_cr cr
    UNION ALL
    SELECT sr.sr_item_sk AS item_sk,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_net_loss AS net_loss
    FROM filtered_sr sr
),
inventory_agg AS (
    SELECT inv.inv_item_sk,
           AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    WHERE inv.inv_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY inv.inv_item_sk
),
promo_agg AS (
    SELECT p.p_item_sk,
           SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_start_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY p.p_item_sk
)
SELECT
    t.i_category,
    t.i_brand,
    t.total_net_loss,
    t.avg_inventory_on_hand,
    t.total_promo_cost,
    RANK() OVER (ORDER BY t.total_net_loss DESC) AS category_rank
FROM (
    SELECT
        i.i_category,
        i.i_brand,
        SUM(cr.net_loss) AS total_net_loss,
        AVG(inv.avg_qty_on_hand) AS avg_inventory_on_hand,
        SUM(promo.total_promo_cost) AS total_promo_cost
    FROM combined_returns cr
    JOIN item i ON cr.item_sk = i.i_item_sk
    LEFT JOIN inventory_agg inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN promo_agg promo ON i.i_item_sk = promo.p_item_sk
    GROUP BY i.i_category, i.i_brand
    HAVING SUM(cr.net_loss) > 0
) t
ORDER BY t.total_net_loss DESC
LIMIT 5
