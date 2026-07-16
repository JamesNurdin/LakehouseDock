SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.s_store_id,
    agg.s_city,
    agg.w_warehouse_name,
    agg.w_warehouse_sq_ft,
    agg.catalog_return_orders,
    agg.catalog_total_net_loss,
    agg.web_return_orders,
    agg.web_total_net_loss,
    (agg.catalog_total_net_loss + agg.web_total_net_loss) / NULLIF(agg.w_warehouse_sq_ft, 0) AS total_net_loss_per_sq_ft,
    agg.avg_catalog_return_qty,
    agg.avg_web_return_qty,
    CASE
        WHEN agg.catalog_total_net_loss > agg.web_total_net_loss THEN 'Catalog higher loss'
        WHEN agg.catalog_total_net_loss < agg.web_total_net_loss THEN 'Web higher loss'
        ELSE 'Equal loss'
    END AS loss_comparison,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year, agg.d_month_seq ORDER BY agg.catalog_total_net_loss DESC) AS catalog_loss_rank_by_month
FROM (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_net_loss) AS catalog_total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(wr.wr_net_loss) AS web_total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        w.w_warehouse_name,
        w.w_warehouse_sq_ft
    HAVING COUNT(DISTINCT cr.cr_order_number) > 0 OR COUNT(DISTINCT wr.wr_order_number) > 0
) agg
ORDER BY agg.d_year, agg.d_month_seq, agg.s_store_id
LIMIT 100
