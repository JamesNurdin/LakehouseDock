WITH base_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        c.c_birth_month,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND c.c_birth_month IN (1, 4, 6, 7)
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        c.c_birth_month
)
SELECT
    ba.cp_catalog_page_id,
    ba.cp_department,
    AVG(ba.total_return_amount) AS avg_total_return_amount,
    SUM(ba.return_cnt) AS total_returns,
    MAX(ba.avg_return_amount) AS max_avg_return_amount
FROM base_agg ba
WHERE ba.total_return_amount > 1000
GROUP BY ba.cp_catalog_page_id, ba.cp_department
HAVING SUM(ba.return_cnt) >= 5
ORDER BY avg_total_return_amount DESC
LIMIT 100
