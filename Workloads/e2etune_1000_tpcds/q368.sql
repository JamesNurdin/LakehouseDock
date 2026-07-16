WITH cat_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        p.p_promo_name AS promo_name,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        SUM(cr.cr_return_quantity) AS cat_return_qty,
        AVG(p.p_cost) AS avg_promo_cost,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p ON cr.cr_item_sk = p.p_item_sk
        AND cr.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = cr.cr_item_sk
        AND inv.inv_date_sk = cr.cr_returned_date_sk
        AND inv.inv_warehouse_sk = cr.cr_warehouse_sk
    WHERE cr.cr_net_loss > 1000
    GROUP BY r.r_reason_desc, p.p_promo_name
),
store_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        p.p_promo_name AS promo_name,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN promotion p ON sr.sr_item_sk = p.p_item_sk
        AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE sr.sr_net_loss > 1000
    GROUP BY r.r_reason_desc, p.p_promo_name
)
SELECT
    COALESCE(c.reason_desc, s.reason_desc) AS reason_desc,
    COALESCE(c.promo_name, s.promo_name) AS promo_name,
    COALESCE(c.cat_net_loss, 0) AS total_catalog_net_loss,
    COALESCE(s.store_net_loss, 0) AS total_store_net_loss,
    COALESCE(c.cat_return_qty, 0) + COALESCE(s.store_return_qty, 0) AS total_return_quantity,
    COALESCE(c.avg_promo_cost, 0) AS avg_promo_cost,
    COALESCE(c.total_inventory_on_hand, 0) AS total_inventory_on_hand
FROM cat_agg c
FULL OUTER JOIN store_agg s
    ON c.reason_desc = s.reason_desc
    AND c.promo_name = s.promo_name
ORDER BY (COALESCE(c.cat_net_loss, 0) + COALESCE(s.store_net_loss, 0)) DESC
LIMIT 100
