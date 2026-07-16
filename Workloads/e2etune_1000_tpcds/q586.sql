WITH agg AS (
    SELECT
        ws.web_city,
        ws.web_state,
        i.inv_warehouse_sk,
        i.inv_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        CASE 
            WHEN SUM(i.inv_quantity_on_hand) = 0 THEN NULL
            ELSE SUM(cr.cr_return_quantity) * 1.0 / SUM(i.inv_quantity_on_hand)
        END AS return_to_inventory_ratio
    FROM catalog_returns cr
    JOIN inventory i
        ON cr.cr_item_sk = i.inv_item_sk
        AND cr.cr_warehouse_sk = i.inv_warehouse_sk
        AND cr.cr_returned_date_sk = i.inv_date_sk
    JOIN web_site ws
        ON i.inv_warehouse_sk = ws.web_site_sk
    WHERE
        cr.cr_return_ship_cost > 0
        AND cr.cr_return_tax > 10
        AND ws.web_gmt_offset BETWEEN -5 AND 5
    GROUP BY
        ws.web_city,
        ws.web_state,
        i.inv_warehouse_sk,
        i.inv_item_sk
    HAVING
        SUM(cr.cr_return_quantity) > 10
)
SELECT
    web_city,
    web_state,
    inv_warehouse_sk,
    inv_item_sk,
    total_return_qty,
    total_net_loss,
    total_inventory_qty,
    avg_return_amount,
    return_to_inventory_ratio,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 10
