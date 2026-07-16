WITH sales_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_quantity) AS avg_quantity,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
returns_agg AS (
    SELECT
        cd.cd_demo_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_store_credit) AS total_store_credit,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cd.cd_demo_sk
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.cd_education_status,
    s.sales_cnt,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cd_demo_sk = r.cd_demo_sk
WHERE s.total_sales > 10000
ORDER BY net_sales DESC
LIMIT 100
