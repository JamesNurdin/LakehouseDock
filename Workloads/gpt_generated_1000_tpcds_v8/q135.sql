WITH joined AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_refunded_customer_sk,
        w.w_warehouse_name,
        r.r_reason_desc,
        sm.sm_ship_mode_id,
        i.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer rc
        ON cr.cr_refunded_customer_sk = rc.c_customer_sk
    JOIN customer_address rca
        ON cr.cr_refunded_addr_sk = rca.ca_address_sk
    JOIN customer retc
        ON cr.cr_returning_customer_sk = retc.c_customer_sk
    JOIN customer_address reta
        ON cr.cr_returning_addr_sk = reta.ca_address_sk
),
agg AS (
    SELECT
        w_warehouse_name,
        r_reason_desc,
        sm_ship_mode_id,
        cr_refunded_customer_sk,
        COUNT(*) AS returns_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        (
            SELECT MAX(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_refunded_customer_sk = joined.cr_refunded_customer_sk
        ) AS max_return_by_refunded_customer
    FROM joined
    GROUP BY w_warehouse_name, r_reason_desc, sm_ship_mode_id, cr_refunded_customer_sk
    HAVING SUM(cr_return_amount) > 500
)
SELECT
    w_warehouse_name,
    r_reason_desc,
    sm_ship_mode_id,
    returns_cnt,
    total_return_amount,
    avg_return_amount,
    total_inventory_on_hand,
    max_return_by_refunded_customer,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_return_amount DESC) AS warehouse_return_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
