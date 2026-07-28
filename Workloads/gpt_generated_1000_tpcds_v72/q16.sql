WITH agg_by_warehouse_year AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        d.d_year AS year,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
        CASE
            WHEN SUM(cr.cr_return_amount) > 10000 THEN 'HIGH'
            ELSE 'NORMAL'
        END AS catalog_return_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN store_returns sr
        ON cr.cr_item_sk = sr.sr_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd_store
        ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cr.cr_return_amount > 100
      AND hd_ref.hd_income_band_sk IN (4, 5, 6, 7)
      AND w.w_warehouse_name NOT LIKE 'Bad%'
    GROUP BY GROUPING SETS (
        (w.w_warehouse_name, d.d_year),
        (w.w_warehouse_name),
        (d.d_year),
        ()
    )
)
SELECT
    warehouse_name,
    year,
    total_catalog_net_loss,
    total_store_net_loss,
    catalog_orders,
    store_tickets,
    catalog_return_category,
    (total_catalog_net_loss + total_store_net_loss) / NULLIF(catalog_orders + store_tickets, 0) AS avg_loss_per_transaction
FROM agg_by_warehouse_year
WHERE (total_catalog_net_loss + total_store_net_loss) > 5000
ORDER BY warehouse_name ASC, year DESC
LIMIT 100
