/*
Goal: Identify customers (by refunded customer) with high return activity, joining return data, customer info, and demographic attributes. The query aggregates returns per customer in a CTE, enriches with customer and demographic details, applies multiple filters, derives a dependency category, uses a window function to rank customers within each birth country, and includes scalar subqueries and an EXISTS filter. Results are ordered by total return amount and limited to the top 100.
*/
WITH cr_agg AS (
    SELECT
        cr_refunded_customer_sk,
        cr_returning_customer_sk,
        COUNT(*) AS return_cnt,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax,
        AVG(cr_return_amt_inc_tax) AS avg_return_inc_tax
    FROM catalog_returns
    WHERE cr_return_amount > 20
      AND cr_return_tax >= 0
      AND cr_return_quantity >= 1
      AND cr_returning_addr_sk IN (4104524, 62663, 3021775, 91422, 1013766)
      AND cr_refunded_customer_sk NOT IN (0)
      AND cr_returned_date_sk BETWEEN 2449000 AND 2453000
    GROUP BY cr_refunded_customer_sk, cr_returning_customer_sk
),
customer_agg AS (
    SELECT
        agg.cr_refunded_customer_sk,
        c.c_customer_id,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        agg.return_cnt,
        agg.total_return_amount,
        agg.avg_return_inc_tax,
        CASE WHEN cd.cd_dep_count > 3 THEN 'HIGH_DEP' ELSE 'LOW_DEP' END AS dep_category
    FROM cr_agg agg
    JOIN customer c
        ON agg.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_country IN ('JAPAN', 'CYPRUS', 'RWANDA')
      AND cd.cd_gender = 'F'
      AND cd.cd_marital_status IN ('M', 'S')
      AND agg.total_return_amount > 1000
      AND agg.return_cnt >= 5
)
SELECT
    ca.c_customer_id,
    ca.c_birth_country,
    ca.dep_category,
    ca.return_cnt,
    ca.total_return_amount,
    ca.avg_return_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY ca.c_birth_country ORDER BY ca.total_return_amount DESC) AS rn_within_country,
    (SELECT MAX(total_return_amount) FROM customer_agg) AS global_max_return_amount,
    (SELECT COUNT(*) FROM catalog_returns cr3 WHERE cr3.cr_refunded_customer_sk = ca.cr_refunded_customer_sk AND cr3.cr_return_amount > 200) AS high_value_return_cnt
FROM customer_agg ca
WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr4
    WHERE cr4.cr_refunded_customer_sk = ca.cr_refunded_customer_sk
      AND cr4.cr_return_tax > 5
)
ORDER BY ca.total_return_amount DESC
LIMIT 100
