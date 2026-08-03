WITH base AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        w.w_state,
        w.w_warehouse_id,
        w.w_street_number,
        w.w_street_type,
        sm.sm_carrier,
        sm.sm_contract
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(sm.sm_contract, '[A-Z]{2}[0-9]')
      AND w.w_state LIKE 'M%'
      AND regexp_like(w.w_street_type, '^R')
),
sub1 AS (
    SELECT DISTINCT cr_warehouse_sk
    FROM base
    WHERE substr(w_street_number, 1, 1) = '6'
),
sub2 AS (
    SELECT DISTINCT cr_warehouse_sk
    FROM base
    WHERE substr(w_street_number, 1, 1) = '3'
),
intersect_warehouses AS (
    SELECT cr_warehouse_sk FROM sub1
    INTERSECT
    SELECT cr_warehouse_sk FROM sub2
),
agg AS (
    SELECT
        b.cr_warehouse_sk,
        b.w_state,
        b.w_warehouse_id,
        b.sm_carrier,
        MIN(b.sm_contract) AS sm_contract,
        SUM(b.cr_return_amount) AS total_return_amount,
        SUM(b.cr_return_quantity) AS total_return_quantity,
        CASE WHEN SUM(b.cr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
    FROM base b
    JOIN intersect_warehouses i ON b.cr_warehouse_sk = i.cr_warehouse_sk
    GROUP BY b.cr_warehouse_sk, b.w_state, b.w_warehouse_id, b.sm_carrier
)
SELECT
    a.w_warehouse_id,
    a.w_state,
    a.sm_carrier,
    CONCAT(a.w_state, '-', a.sm_carrier) AS state_carrier_key,
    regexp_extract(a.sm_contract, '([0-9]+)', 1) AS contract_number,
    a.total_return_amount,
    a.total_return_quantity,
    a.loss_flag,
    CASE WHEN a.total_return_amount > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
    ROW_NUMBER() OVER () AS global_row_num,
    RANK() OVER (PARTITION BY a.w_state ORDER BY a.total_return_amount DESC) AS state_rank
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
