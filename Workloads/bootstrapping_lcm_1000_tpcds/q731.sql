WITH
    inv_agg AS (
        SELECT
            inv_date_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_date_sk, inv_warehouse_sk
    ),
    ret_agg AS (
        SELECT
            cr_returned_date_sk,
            cr_warehouse_sk,
            SUM(cr_net_loss) AS total_net_loss,
            COUNT(*) AS returns_cnt,
            MAX(cr_return_amount) AS max_return_amount,
            MIN(cr_return_amount) AS min_return_amount
        FROM catalog_returns
        GROUP BY cr_returned_date_sk, cr_warehouse_sk
    )
SELECT
    d.d_year,
    d.d_current_month,
    w.w_warehouse_name,
    w.w_state,
    i.total_qty_on_hand,
    r.total_net_loss,
    r.returns_cnt,
    r.max_return_amount,
    r.min_return_amount,
    AVG(s.s_number_employees) AS avg_store_employees,
    i.total_qty_on_hand * r.total_net_loss AS weighted_loss
FROM ret_agg r
JOIN inv_agg i
    ON r.cr_returned_date_sk = i.inv_date_sk
   AND r.cr_warehouse_sk = i.inv_warehouse_sk
JOIN date_dim d
    ON r.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w
    ON r.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE w.w_state IN ('CA', 'TX')
  AND d.d_year >= 2020
GROUP BY
    d.d_year,
    d.d_current_month,
    w.w_warehouse_name,
    w.w_state,
    i.total_qty_on_hand,
    r.total_net_loss,
    r.returns_cnt,
    r.max_return_amount,
    r.min_return_amount
HAVING r.total_net_loss > 0
ORDER BY r.total_net_loss DESC
LIMIT 100
