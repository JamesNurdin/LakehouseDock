WITH sampled_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_warehouse_sk,
        cr_refunded_customer_sk,
        cr_return_amount,
        cr_returned_time_sk,
        cr_return_quantity,
        cr_return_tax,
        cr_return_amt_inc_tax,
        cr_fee,
        cr_return_ship_cost,
        cr_refunded_cash,
        cr_reversed_charge,
        cr_store_credit,
        cr_net_loss
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
returns_2022 AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        MAX(d.d_date) AS latest_return_date
    FROM sampled_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2022
    GROUP BY w.w_warehouse_id, w.w_warehouse_sk
),
high_potential_warehouses AS (
    SELECT DISTINCT w.w_warehouse_sk
    FROM sampled_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_buy_potential IN ('>10000', '5001-10000')
),
intersected_warehouses AS (
    SELECT w_warehouse_sk FROM returns_2022
    INTERSECT
    SELECT w_warehouse_sk FROM high_potential_warehouses
)
SELECT
    r.w_warehouse_id,
    r.total_return_amount,
    r.return_cnt,
    r.latest_return_date
FROM returns_2022 r
WHERE r.w_warehouse_sk IN (SELECT w_warehouse_sk FROM intersected_warehouses)

UNION

SELECT
    w.w_warehouse_id,
    agg.total_return_amount,
    agg.return_cnt,
    agg.latest_return_date
FROM (
    SELECT
        w.w_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        MAX(d.d_date) AS latest_return_date
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2022
    GROUP BY w.w_warehouse_sk
) agg
JOIN warehouse w
    ON agg.w_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT cr2.cr_returned_time_sk) AS distinct_return_times
    FROM catalog_returns cr2
    WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
) lt
WHERE lt.distinct_return_times > 5
LIMIT 100
