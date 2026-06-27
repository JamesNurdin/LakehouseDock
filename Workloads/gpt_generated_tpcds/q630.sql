WITH sales_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        sum(ss.ss_ext_sales_price) AS total_sales_amount,
        sum(ss.ss_net_profit) AS total_sales_profit,
        count(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        count(*) AS sales_transactions
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
returns_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        sum(cr.cr_return_amount) AS total_return_amount,
        sum(cr.cr_net_loss) AS total_return_loss,
        count(DISTINCT cr.cr_refunded_customer_sk) AS distinct_return_customers,
        count(*) AS return_transactions
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    coalesce(s.cd_gender, r.cd_gender) AS gender,
    coalesce(s.cd_marital_status, r.cd_marital_status) AS marital_status,
    s.total_sales_amount,
    s.total_sales_profit,
    s.distinct_customers,
    s.sales_transactions,
    r.total_return_amount,
    r.total_return_loss,
    r.distinct_return_customers,
    r.return_transactions,
    (s.total_sales_amount - r.total_return_amount) AS net_sales_amount,
    (s.total_sales_profit - r.total_return_loss) AS net_contribution
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.cd_gender = r.cd_gender
   AND s.cd_marital_status = r.cd_marital_status
ORDER BY gender, marital_status
