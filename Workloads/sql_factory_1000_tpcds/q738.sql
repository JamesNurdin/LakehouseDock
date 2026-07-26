WITH ranked_returns AS (
    SELECT
        cr.cr_order_number,
        d.d_year,
        cr.cr_return_amt_inc_tax,
        cr.cr_return_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        w.w_warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_return_amt_inc_tax DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
)
SELECT
    d_year AS year,
    cr_order_number AS order_number,
    cr_return_amt_inc_tax AS return_amt_inc_tax,
    cr_return_quantity AS return_quantity,
    cd_gender AS gender,
    cd_marital_status AS marital_status,
    w_warehouse_name AS warehouse_name
FROM ranked_returns
WHERE rn <= 5
ORDER BY year, rn
