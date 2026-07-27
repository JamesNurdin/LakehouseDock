WITH returns_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        w.w_warehouse_name,
        td.t_hour,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cr.cr_return_amount > 10.00
        AND cr.cr_return_quantity >= 1
        AND w.w_gmt_offset BETWEEN -5.00 AND 0.00
        AND EXISTS (
            SELECT 1
            FROM store_sales ss
            JOIN time_dim td2 ON ss.ss_sold_time_sk = td2.t_time_sk
            WHERE ss.ss_addr_sk = ca.ca_address_sk
              AND td2.t_hour = td.t_hour
              AND td2.t_minute = td.t_minute
              AND ss.ss_quantity > 0
        )
    GROUP BY
        cp.cp_catalog_page_id,
        w.w_warehouse_name,
        td.t_hour
)
SELECT DISTINCT
    cp_catalog_page_id,
    w_warehouse_name,
    t_hour,
    total_net_loss,
    return_cnt,
    total_qty_on_hand,
    total_net_loss / NULLIF(return_cnt, 0) AS avg_loss_per_return
FROM (
    SELECT
        cp_catalog_page_id,
        w_warehouse_name,
        t_hour,
        total_net_loss,
        return_cnt,
        total_qty_on_hand,
        ROW_NUMBER() OVER (PARTITION BY cp_catalog_page_id ORDER BY total_net_loss DESC) AS rn
    FROM returns_agg
) r
WHERE rn = 1
ORDER BY total_net_loss DESC
LIMIT 100
