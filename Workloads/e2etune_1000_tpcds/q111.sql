WITH unified_returns AS (
    SELECT cr.cr_item_sk AS item_sk,
           r.r_reason_desc AS reason_desc,
           cr.cr_returned_date_sk AS returned_date_sk,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS return_qty
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
    UNION ALL
    SELECT sr.sr_item_sk,
           r.r_reason_desc,
           sr.sr_returned_date_sk,
           sr.sr_net_loss,
           sr.sr_return_quantity
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
    UNION ALL
    SELECT wr.wr_item_sk,
           r.r_reason_desc,
           wr.wr_returned_date_sk,
           wr.wr_net_loss,
           wr.wr_return_quantity
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
),
inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
item_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           i.i_brand,
           ur.reason_desc,
           SUM(ur.net_loss) AS total_net_loss,
           SUM(ur.return_qty) AS total_return_qty,
           COUNT(DISTINCT ur.returned_date_sk) AS active_return_days,
           SUM(ur.net_loss) / NULLIF(SUM(ur.return_qty), 0) AS avg_loss_per_unit,
           inv.total_on_hand
    FROM unified_returns ur
    JOIN item i ON ur.item_sk = i.i_item_sk
    LEFT JOIN inventory_agg inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_id, i.i_category, i.i_brand, ur.reason_desc, inv.total_on_hand
),
ranked_items AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
    FROM item_agg
    WHERE total_on_hand IS NOT NULL AND total_on_hand < 200
)
SELECT loss_rank,
       i_item_id,
       i_category,
       i_brand,
       reason_desc,
       ROUND(total_net_loss, 2) AS total_net_loss,
       total_return_qty,
       active_return_days,
       ROUND(avg_loss_per_unit, 2) AS avg_loss_per_unit,
       total_on_hand
FROM ranked_items
WHERE loss_rank <= 100
ORDER BY loss_rank
