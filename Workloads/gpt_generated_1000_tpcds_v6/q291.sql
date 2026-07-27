WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_coupon_amt,
        sr.sr_return_amt_inc_tax,
        sr.sr_store_credit,
        CASE 
            WHEN cd.cd_education_status = 'College' THEN 1
            WHEN cd.cd_education_status = '4 yr Degree' THEN 2
            ELSE 0
        END AS edu_score
    FROM customer c
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND c.c_birth_year BETWEEN 1960 AND 1980
      AND ws.ws_coupon_amt > 100
      AND sr.sr_return_amt_inc_tax > 200
),
agg AS (
    SELECT
        cd_demo_sk,
        edu_score,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        SUM(ws_quantity) AS total_qty,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(sr_return_amt_inc_tax) AS total_return,
        AVG(ws_coupon_amt) AS avg_coupon,
        SUM(ws_ext_sales_price) - SUM(sr_return_amt_inc_tax) AS net_sales_minus_returns
    FROM joined_data
    GROUP BY cd_demo_sk, edu_score
)
SELECT
    cd_demo_sk,
    edu_score,
    num_customers,
    total_qty,
    total_sales,
    total_return,
    net_sales_minus_returns,
    RANK() OVER (ORDER BY net_sales_minus_returns DESC) AS sales_return_rank,
    SUM(total_sales) OVER (PARTITION BY edu_score) AS total_sales_by_edu
FROM agg
WHERE total_sales > 10000
  AND num_customers >= 5
ORDER BY net_sales_minus_returns DESC
LIMIT 100
