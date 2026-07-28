WITH total_sales AS (
    SELECT sum(ss_ext_sales_price) AS total_sales_all
    FROM store_sales
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    concat(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
    count(cr.cr_order_number) AS return_cnt,
    avg(cr.cr_return_amount) AS avg_return_amount,
    sum(cr.cr_return_amount) AS total_return_amount,
    (SELECT total_sales_all FROM total_sales) AS total_sales_all
FROM catalog_returns cr
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE regexp_like(r.r_reason_desc, '^C.*')
  AND sm.sm_carrier LIKE 'Fed%'
  AND cd.cd_gender = 'M'
  AND cr.cr_item_sk IN (
        SELECT ss_item_sk
        FROM store_sales
        WHERE ss_ext_sales_price > 100
    )
GROUP BY cd.cd_gender, cd.cd_marital_status, concat(cd.cd_gender, '-', cd.cd_marital_status)
ORDER BY avg_return_amount DESC
