WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        cd_sales.cd_gender AS sale_gender,
        cd_current.cd_education_status AS current_education,
        COUNT(*) AS num_transactions,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd_sales
        ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
    JOIN customer_demographics cd_current
        ON c.c_current_cdemo_sk = cd_current.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453000
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year >= 1960
    GROUP BY ss.ss_store_sk, cd_sales.cd_gender, cd_current.cd_education_status
)
SELECT
    ss_store_sk,
    sale_gender,
    current_education,
    num_transactions,
    total_net_paid,
    total_profit,
    avg_discount,
    total_quantity,
    RANK() OVER (PARTITION BY ss_store_sk ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY ss_store_sk ORDER BY sale_gender ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_by_gender
FROM sales_agg
WHERE num_transactions >= 5
ORDER BY ss_store_sk, profit_rank
LIMIT 200
