WITH aggregated_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name AS store_name,
        w.w_warehouse_name AS warehouse_name,
        COUNT(DISTINCT cr.cr_order_number) AS num_catalog_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_store_returns,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(sr.sr_return_amt) AS total_store_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        w.w_warehouse_name
)
SELECT
    ar.d_year,
    ar.d_month_seq,
    ar.store_name,
    ar.warehouse_name,
    ar.num_catalog_returns,
    ar.num_store_returns,
    ar.catalog_net_loss,
    ar.store_net_loss,
    (ar.catalog_net_loss + ar.store_net_loss) AS total_combined_net_loss,
    ar.total_catalog_return_amount,
    ar.total_store_return_amount,
    (ar.total_catalog_return_amount + ar.total_store_return_amount) AS combined_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ar.d_year ORDER BY (ar.catalog_net_loss + ar.store_net_loss) DESC) AS loss_rank_by_year
FROM aggregated_returns ar
ORDER BY total_combined_net_loss DESC
LIMIT 100
