WITH return_summary AS (
    SELECT
        i.i_item_id,
        i.i_category,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
        MAX(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS has_discount_active
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    WHERE i.i_current_price > 20
      AND p.p_channel_tv = 'N'
      AND r.r_reason_id = 'AAAAAAAAFAAAAAAA'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_category, r.r_reason_desc
)
SELECT
    rs.i_category,
    rs.r_reason_desc,
    SUM(rs.catalog_net_loss + rs.store_net_loss) AS total_net_loss,
    AVG(rs.avg_inventory_qty) AS avg_inventory,
    COUNT(DISTINCT rs.i_item_id) AS distinct_items
FROM return_summary rs
WHERE rs.catalog_net_loss > 0
  AND rs.store_net_loss > 0
  AND rs.has_discount_active = 1
GROUP BY rs.i_category, rs.r_reason_desc
HAVING SUM(rs.catalog_net_loss + rs.store_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
