WITH raw_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        w.w_warehouse_name,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        AVG(sr.sr_return_quantity) AS avg_store_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY s.s_store_id, d.d_year, w.w_warehouse_name
),
ranked AS (
    SELECT
        s_store_id,
        d_year,
        w_warehouse_name,
        catalog_return_orders,
        total_catalog_net_loss,
        store_return_tickets,
        total_store_net_loss,
        avg_catalog_return_qty,
        avg_store_return_qty,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_store_net_loss DESC) AS store_year_rank
    FROM raw_agg
)
SELECT
    s_store_id,
    d_year,
    w_warehouse_name,
    catalog_return_orders,
    total_catalog_net_loss,
    store_return_tickets,
    total_store_net_loss,
    avg_catalog_return_qty,
    avg_store_return_qty,
    store_year_rank
FROM ranked
WHERE store_year_rank <= 3
ORDER BY total_store_net_loss DESC
LIMIT 100
