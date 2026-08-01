WITH
    agg_returns AS (
        SELECT
            cr_warehouse_sk,
            cr_returned_date_sk,
            cr_refunded_cdemo_sk,
            cr_returning_cdemo_sk,
            cr_order_number,
            SUM(cr_return_amount) AS sum_return_amount,
            AVG(cr_return_quantity) AS avg_return_quantity,
            COUNT(*) AS cnt_returns
        FROM catalog_returns
        WHERE cr_returned_time_sk BETWEEN 30000 AND 70000
          AND cr_returned_date_sk >= 19940101
          AND cr_returned_date_sk <= 19941231
          AND cr_return_amount > 10.00
          AND cr_return_quantity > 0
          AND cr_reversed_charge < 200.00
          AND cr_fee >= 0.00
          AND cr_return_ship_cost <= 20.00
        GROUP BY cr_warehouse_sk, cr_returned_date_sk, cr_refunded_cdemo_sk, cr_returning_cdemo_sk, cr_order_number
    ),
    joined_data AS (
        SELECT
            ar.cr_warehouse_sk,
            w.w_warehouse_name,
            w.w_state,
            w.w_county,
            ref_cd.cd_gender AS refunded_gender,
            ret_cd.cd_gender AS returning_gender,
            ar.cr_returned_date_sk,
            ar.sum_return_amount,
            ar.avg_return_quantity,
            ar.cnt_returns,
            lc.city_starts_a
        FROM agg_returns ar
        JOIN warehouse w
            ON ar.cr_warehouse_sk = w.w_warehouse_sk
        JOIN customer_demographics ref_cd
            ON ar.cr_refunded_cdemo_sk = ref_cd.cd_demo_sk
        JOIN customer_demographics ret_cd
            ON ar.cr_returning_cdemo_sk = ret_cd.cd_demo_sk
        LEFT JOIN LATERAL (
            SELECT CASE WHEN w.w_city LIKE 'A%' THEN 1 ELSE 0 END AS city_starts_a
        ) lc ON true
        WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = ar.cr_order_number
              AND cr2.cr_return_amount > 5000.00
        )
          AND ref_cd.cd_dep_count BETWEEN 1 AND 5
          AND ret_cd.cd_purchase_estimate >= 4000
          AND w.w_gmt_offset BETWEEN -5.00 AND 5.00
          AND w.w_suite_number = 'Suite 90'
    )
SELECT
    jd.cr_warehouse_sk,
    jd.w_warehouse_name,
    jd.w_state,
    jd.w_county,
    jd.refunded_gender,
    jd.returning_gender,
    jd.cr_returned_date_sk,
    jd.sum_return_amount,
    jd.avg_return_quantity,
    jd.cnt_returns,
    jd.city_starts_a,
    ROW_NUMBER() OVER (ORDER BY jd.sum_return_amount DESC) AS rn
FROM (
    SELECT * FROM joined_data WHERE w_state = 'CA'
    UNION DISTINCT
    SELECT * FROM joined_data WHERE w_state = 'TX'
) jd
ORDER BY rn
LIMIT 100
