WITH excluded_items AS (
    SELECT p.p_item_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
    EXCEPT
    SELECT cr.cr_item_sk
    FROM catalog_returns cr
    WHERE cr.cr_net_loss > 1000
)
SELECT
    w.w_warehouse_name,
    i.i_product_name,
    SUM(cr.cr_net_loss) AS sum_cr_net_loss,
    SUM(sr.sr_net_loss) AS sum_sr_net_loss,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) AS total_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) DESC
    ) AS loss_rank,
    CASE WHEN (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) > 5000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    t.t_sub_shift,
    inv.inv_quantity_on_hand,
    p.p_promo_name
FROM catalog_returns cr
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_return_time_sk = t.t_time_sk
WHERE t.t_sub_shift = 'morning'
  AND inv.inv_quantity_on_hand > 500
  AND p.p_channel_demo = 'N'
  AND i.i_item_sk NOT IN (
        SELECT sr2.sr_item_sk
        FROM store_returns sr2
        WHERE sr2.sr_return_quantity > 5
    )
  AND i.i_item_sk IN (SELECT p_item_sk FROM excluded_items)
GROUP BY
    w.w_warehouse_name,
    i.i_product_name,
    t.t_sub_shift,
    inv.inv_quantity_on_hand,
    p.p_promo_name
ORDER BY total_net_loss DESC
LIMIT 100
