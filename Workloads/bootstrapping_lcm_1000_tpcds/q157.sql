WITH returns_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_warehouse_sk,
        SUM(cr_return_amount)          AS total_return_amount,
        SUM(cr_return_tax)             AS total_return_tax,
        SUM(cr_net_loss)               AS total_net_loss,
        COUNT(DISTINCT cr_returning_customer_sk) AS distinct_returning_customers
    FROM catalog_returns
    GROUP BY cr_returned_date_sk, cr_warehouse_sk
),
inventory_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        AVG(inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_warehouse_sk
),
store_closure_agg AS (
    SELECT
        s_closed_date_sk,
        SUM(s_floor_space) AS total_floor_space_closed
    FROM store
    GROUP BY s_closed_date_sk
)
SELECT
    d.d_year,
    d.d_moy                              AS month,
    w.w_state,
    w.w_warehouse_name,
    SUM(r.total_return_amount)           AS sum_return_amount,
    SUM(r.total_return_tax)              AS sum_return_tax,
    SUM(r.total_net_loss)                AS sum_net_loss,
    SUM(r.distinct_returning_customers)  AS sum_distinct_customers,
    AVG(i.avg_qty_on_hand)               AS avg_inventory_quantity,
    COALESCE(SUM(s.total_floor_space_closed), 0) AS sum_store_floor_space_closed
FROM returns_agg r
JOIN date_dim d
    ON r.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON r.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_agg i
    ON i.inv_date_sk = d.d_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_closure_agg s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY d.d_year, d.d_moy, w.w_state, w.w_warehouse_name
HAVING SUM(r.total_return_amount) > 0
ORDER BY d.d_year, month, w.w_state
LIMIT 100
