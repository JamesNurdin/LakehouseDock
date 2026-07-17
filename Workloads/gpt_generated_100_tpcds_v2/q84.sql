WITH aggregated_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_bill_cdemo_sk AS cdemo_sk,
        cs.cs_catalog_page_sk AS cp_sk,
        cp.cp_department,
        SUM(cs.cs_net_profit) AS total_net_profit,
        MAX(cs.cs_sold_date_sk) AS last_sold_date_sk
    FROM catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cs.cs_bill_customer_sk, cs.cs_bill_cdemo_sk, cs.cs_catalog_page_sk, cp.cp_department
)
SELECT
    agg.cp_department,
    c.c_customer_id,
    cd.cd_gender,
    agg.total_net_profit,
    agg.last_sold_date_sk,
    DENSE_RANK() OVER (PARTITION BY agg.cp_department ORDER BY agg.total_net_profit DESC) AS dept_profit_rank,
    SUM(agg.total_net_profit) OVER (PARTITION BY agg.cp_department ORDER BY agg.last_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_sum_last3,
    CASE
        WHEN agg.total_net_profit >= 10000 THEN 'High'
        WHEN agg.total_net_profit >= 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM aggregated_sales agg
INNER JOIN customer c
    ON agg.cust_sk = c.c_customer_sk
INNER JOIN customer_demographics cd
    ON agg.cdemo_sk = cd.cd_demo_sk
ORDER BY agg.cp_department, dept_profit_rank
