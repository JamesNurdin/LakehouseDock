WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
store_agg AS (
    SELECT
        s_closed_date_sk,
        COUNT(*) AS closed_store_cnt
    FROM store
    GROUP BY s_closed_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    MAX(inv_agg.total_inventory_on_hand) AS total_inventory_on_hand,
    MAX(store_agg.closed_store_cnt) AS closed_store_cnt,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_order_cnt,
    CASE
        WHEN SUM(cr.cr_return_amount) = 0 THEN NULL
        ELSE (SUM(cr.cr_return_amount) - MAX(inv_agg.total_inventory_on_hand) * AVG(cr.cr_return_ship_cost)) / SUM(cr.cr_return_amount)
    END AS return_inventory_ratio,
    GROUPING(d.d_year) AS g_year,
    GROUPING(d.d_month_seq) AS g_month,
    GROUPING(r.r_reason_desc) AS g_reason
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
LEFT JOIN store_agg
    ON store_agg.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND cr.cr_return_amount > 0
GROUP BY ROLLUP (d.d_year, d.d_month_seq, r.r_reason_desc)
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY d.d_year, d.d_month_seq, r.r_reason_desc
