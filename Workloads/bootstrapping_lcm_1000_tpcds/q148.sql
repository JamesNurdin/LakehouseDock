WITH aggregated AS (
    SELECT
        d1.d_year,
        d1.d_quarter_name,
        s.s_store_name,
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
        (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d1.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d2 ON s.s_closed_date_sk = d2.d_date_sk
    GROUP BY d1.d_year, d1.d_quarter_name, s.s_store_name, w.w_warehouse_name
)
SELECT
    d_year,
    d_quarter_name,
    s_store_name,
    w_warehouse_name,
    catalog_net_loss,
    store_net_loss,
    total_net_loss,
    catalog_return_qty,
    store_return_qty,
    catalog_orders,
    store_tickets,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
