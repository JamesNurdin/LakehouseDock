WITH sales_by_store AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        cd.cd_education_status AS education_status,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS revenue,
        SUM(ss.ss_quantity) AS units_sold,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2452285
      AND cd.cd_credit_rating IN ('A', 'B', 'C')
    GROUP BY ss.ss_store_sk, cd.cd_education_status, cd.cd_gender
)
SELECT
    store_sk,
    education_status,
    gender,
    profit,
    revenue,
    units_sold,
    distinct_customers,
    RANK() OVER (PARTITION BY education_status, gender ORDER BY profit DESC) AS profit_rank
FROM sales_by_store
WHERE profit > 50000
ORDER BY education_status, gender, profit_rank
LIMIT 100
