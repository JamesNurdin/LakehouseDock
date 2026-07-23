WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2002
)
SELECT
    fd.d_year AS year,
    'Sales' AS category,
    SUM(cs.cs_net_paid) AS total_amount
FROM
    catalog_sales cs
    JOIN filtered_dates fd ON cs.cs_sold_date_sk = fd.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
GROUP BY
    fd.d_year
UNION ALL
SELECT
    fd.d_year AS year,
    'Returns' AS category,
    SUM(wr.wr_return_amt) AS total_amount
FROM
    web_returns wr
    JOIN filtered_dates fd ON wr.wr_returned_date_sk = fd.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE
    wr.wr_return_tax > 10
    AND cd.cd_gender = 'M'
GROUP BY
    fd.d_year
ORDER BY
    year,
    category
LIMIT 100
