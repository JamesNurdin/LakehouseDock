WITH filtered_sales AS (
    SELECT
        s.ss_ext_sales_price,
        s.ss_net_paid,
        s.ss_net_profit,
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status
    FROM tpcds.store_sales s
    JOIN tpcds.customer c
        ON s.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics d
        ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE c.c_birth_day = 12
      AND c.c_birth_month = 9
      AND c.c_preferred_cust_flag = 'Y'
      AND d.cd_credit_rating = 'Good'
      AND d.cd_dep_employed_count >= 4
      AND s.ss_ext_sales_price > 1000
)
SELECT
    cd_gender,
    cd_marital_status,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_profit) AS avg_profit,
    MIN(ss_ext_sales_price) AS min_sales,
    MAX(ss_ext_sales_price) AS max_sales
FROM filtered_sales
GROUP BY cd_gender, cd_marital_status
ORDER BY total_net_paid DESC
LIMIT 100
