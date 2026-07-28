WITH avg_return_by_warehouse AS (
    SELECT cr_warehouse_sk, AVG(cr_return_amount) AS avg_return_amount
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
)
SELECT
    d_ss.d_year AS sales_year,
    d_cr.d_year AS catalog_return_year,
    inv.inv_warehouse_sk,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(sr_item.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM store_sales ss
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk                                     -- j1
JOIN store_returns sr_item ON sr_item.sr_item_sk = ss.ss_item_sk                              -- j2
JOIN date_dim d_sr_item ON sr_item.sr_returned_date_sk = d_sr_item.d_date_sk                -- j3
JOIN store_returns sr_ticket ON sr_ticket.sr_ticket_number = ss.ss_ticket_number           -- j4
JOIN date_dim d_sr_ticket ON sr_ticket.sr_returned_date_sk = d_sr_ticket.d_date_sk          -- j5
JOIN inventory inv ON inv.inv_date_sk = d_ss.d_date_sk                                         -- j6
JOIN inventory inv2 ON inv2.inv_date_sk = d_sr_item.d_date_sk                                 -- j7
JOIN date_dim d_cr ON inv2.inv_date_sk = d_cr.d_date_sk                                      -- j8
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_cr.d_date_sk                           -- j9
WHERE cr.cr_return_amount > (
    SELECT avg_return_amount
    FROM avg_return_by_warehouse ar
    WHERE ar.cr_warehouse_sk = cr.cr_warehouse_sk
)
GROUP BY ROLLUP (d_ss.d_year, d_cr.d_year, inv.inv_warehouse_sk)
HAVING SUM(ss.ss_net_paid) > 0
ORDER BY total_sales_net_paid DESC
LIMIT 100
