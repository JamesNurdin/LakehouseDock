WITH store_counts AS (
    SELECT d.d_date_sk AS d_date_sk,
           COUNT(DISTINCT s.s_store_id) AS stores_closed
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_date_sk
)
SELECT
    w.w_warehouse_name,
    d.d_year,
    d.d_quarter_name,
    COUNT(cr.cr_order_number) AS returns_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    sc.stores_closed,
    CASE WHEN d.d_holiday IS NOT NULL THEN 'Holiday' ELSE 'Weekday' END AS day_type
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store_counts sc
    ON sc.d_date_sk = d.d_date_sk
WHERE d.d_year >= 2021
GROUP BY
    w.w_warehouse_name,
    d.d_year,
    d.d_quarter_name,
    sc.stores_closed,
    CASE WHEN d.d_holiday IS NOT NULL THEN 'Holiday' ELSE 'Weekday' END
ORDER BY total_net_loss DESC
LIMIT 100
