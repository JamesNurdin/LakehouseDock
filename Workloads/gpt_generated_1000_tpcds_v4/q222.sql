WITH high_value_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_reason_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 1000
      AND cr.cr_return_quantity BETWEEN 1 AND 10
      AND cr.cr_return_tax < 50
      AND cr.cr_fee BETWEEN 0 AND 20
      AND cr.cr_return_ship_cost < 30
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
)
SELECT
    r.r_reason_desc,
    cd.cd_gender,
    COUNT(DISTINCT hv.cr_order_number) AS orders_cnt,
    SUM(hv.cr_return_amount) AS total_return_amount,
    AVG(hv.cr_return_quantity) AS avg_return_qty,
    MIN(hv.cr_return_tax) AS min_tax,
    MAX(hv.cr_return_tax) AS max_tax
FROM high_value_returns hv
JOIN reason r
    ON hv.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON hv.cr_returning_cdemo_sk = cd.cd_demo_sk
WHERE EXISTS (
        SELECT 1
        FROM customer_demographics cd2
        WHERE cd2.cd_demo_sk = hv.cr_refunded_cdemo_sk
          AND cd2.cd_purchase_estimate > 7000
          AND cd2.cd_dep_college_count >= 2
    )
  AND r.r_reason_desc LIKE '%Did not%'
  AND cd.cd_gender = 'M'
GROUP BY r.r_reason_desc, cd.cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
