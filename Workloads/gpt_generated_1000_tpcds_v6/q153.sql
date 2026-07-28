WITH sales_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_ext_sales_price)               AS total_sales,
        SUM(sr.sr_return_amt)                     AS total_store_return,
        SUM(wr.wr_return_amt_inc_tax)             AS total_web_return,
        COUNT(*)                                   AS txn_count
    FROM customer_demographics cd
    INNER JOIN store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
           AND sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN web_returns wr
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IN ('M', 'F')
      AND cd.cd_marital_status IN ('M', 'S')
      AND cd.cd_education_status = 'College'
      AND ss.ss_net_paid_inc_tax > 1000
      AND sr.sr_return_amt > 50
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
    sa.cd_demo_sk,
    sa.cd_gender,
    sa.cd_marital_status,
    sa.cd_education_status,
    sa.total_sales,
    sa.total_store_return,
    sa.total_web_return,
    ROW_NUMBER() OVER (PARTITION BY sa.cd_gender ORDER BY sa.total_sales DESC) AS gender_sales_rank,
    CASE
        WHEN sa.total_web_return > (SELECT AVG(total_web_return) FROM sales_agg) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS web_return_category
FROM sales_agg sa
ORDER BY sa.total_sales DESC
LIMIT 100
