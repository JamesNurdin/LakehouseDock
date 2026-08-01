WITH
    agg_returns AS (
        SELECT
            cr_item_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(CASE WHEN cr_store_credit > 100 THEN cr_store_credit ELSE 0 END) AS high_store_credit_sum,
            COUNT(*) AS return_cnt
        FROM catalog_returns
        WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451500
        GROUP BY cr_item_sk
    ),
    sampled_warehouses AS (
        SELECT *
        FROM warehouse
        TABLESAMPLE BERNOULLI (10)
    ),
    excluded_warehouses AS (
        SELECT w_warehouse_id
        FROM warehouse
        WHERE w_state = 'TX'
    ),
    included_warehouses AS (
        SELECT w_warehouse_id
        FROM sampled_warehouses
        EXCEPT
        SELECT w_warehouse_id FROM excluded_warehouses
    )
SELECT
    w.w_warehouse_name,
    cp.cp_department,
    cd_returning.cd_gender,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ar.high_store_credit_sum) AS sum_high_store_credit,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(CASE WHEN cd_refund.cd_education_status = 'Advanced Degree' THEN cr.cr_return_amount ELSE 0 END) AS adv_degree_return_sum,
    SUM(CASE WHEN cd_refund.cd_gender = 'M' THEN cr.cr_return_amount ELSE 0 END) AS male_return_amount
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i1
    ON cr.cr_item_sk = i1.i_item_sk
JOIN customer_demographics cd_refund
    ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN household_demographics hd_refund
    ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN agg_returns ar
    ON cr.cr_item_sk = ar.cr_item_sk
FULL OUTER JOIN included_warehouses iw
    ON w.w_warehouse_id = iw.w_warehouse_id
WHERE cp.cp_end_date_sk > 2451000
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_customer_sk = cr.cr_returning_customer_sk
          AND cr2.cr_return_amount > 0
    )
GROUP BY
    w.w_warehouse_name,
    cp.cp_department,
    cd_returning.cd_gender,
    cd_refund.cd_gender,
    cd_refund.cd_education_status
ORDER BY total_return_amount DESC
LIMIT 100
