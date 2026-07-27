WITH joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        d_ret.d_date,
        d_ret.d_year,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        cp.cp_catalog_page_number,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ret.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    store_sk,
    store_name,
    warehouse_name,
    metric,
    metric_value,
    metric_rank
FROM (
    SELECT
        s_store_sk AS store_sk,
        s_store_name AS store_name,
        w_warehouse_name AS warehouse_name,
        'return_amount' AS metric,
        SUM(sr_return_amt) AS metric_value,
        RANK() OVER (ORDER BY SUM(sr_return_amt) DESC) AS metric_rank
    FROM joined_data
    GROUP BY s_store_sk, s_store_name, w_warehouse_name

    UNION ALL

    SELECT
        s_store_sk AS store_sk,
        s_store_name AS store_name,
        w_warehouse_name AS warehouse_name,
        'fee' AS metric,
        SUM(sr_fee) AS metric_value,
        RANK() OVER (ORDER BY SUM(sr_fee) DESC) AS metric_rank
    FROM joined_data
    GROUP BY s_store_sk, s_store_name, w_warehouse_name
) AS combined
ORDER BY metric_value DESC, metric
LIMIT 100
