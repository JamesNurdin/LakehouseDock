WITH catalog_sub AS (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amt_inc_tax AS return_amount,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        'catalog' AS return_channel
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 8000
      AND cd.cd_education_status = 'Advanced Degree'
),
web_sub AS (
    SELECT
        wr.wr_order_number AS order_number,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt_inc_tax AS return_amount,
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        'web' AS return_channel
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 8000
      AND cd.cd_education_status = 'Advanced Degree'
),
combined AS (
    SELECT * FROM catalog_sub
    UNION ALL
    SELECT * FROM web_sub
)
SELECT
    c.order_number,
    c.return_quantity,
    c.return_amount,
    c.reason_desc,
    c.gender,
    c.return_channel,
    (SELECT avg(return_amount) FROM combined) AS overall_avg_return
FROM combined c
WHERE c.return_amount > (SELECT avg(return_amount) FROM combined)
ORDER BY c.return_amount DESC
LIMIT 100
