WITH first_part AS (
    SELECT
        cr.cr_order_number,
        dd.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.web_country,
        cr.cr_return_amount,
        cr.cr_fee
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2001
      AND ws.web_country = 'United States'
      AND ws.web_gmt_offset = -5.00
      AND ws.web_street_type = 'Ave'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_dep_employed_count >= 2
      AND cr.cr_return_amount > 50.00
      AND cr.cr_returned_date_sk IN (
          SELECT d_date_sk FROM date_dim WHERE d_year = 2001
      )
),
second_part AS (
    SELECT
        cr.cr_order_number,
        dd.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.web_country,
        cr.cr_return_amount,
        cr.cr_fee
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_site ws ON ws.web_close_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2002
      AND ws.web_country = 'United States'
      AND ws.web_gmt_offset = -6.00
      AND ws.web_street_type = 'Drive'
      AND cd.cd_marital_status = 'S'
      AND cd.cd_dep_employed_count <= 3
      AND cr.cr_return_amount BETWEEN 30.00 AND 200.00
      AND cr.cr_returned_date_sk IN (
          SELECT d_date_sk FROM date_dim WHERE d_year = 2002
      )
)
SELECT
    d_year,
    cd_gender,
    cd_marital_status,
    web_country,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_fee) AS avg_fee,
    MIN(cr_return_amount) AS min_return,
    MAX(cr_return_amount) AS max_return
FROM (
    SELECT * FROM first_part
    UNION
    SELECT * FROM second_part
) u
GROUP BY d_year, cd_gender, cd_marital_status, web_country
ORDER BY total_return_amount DESC
LIMIT 20
