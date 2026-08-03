WITH catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(cs.cs_net_paid) AS total_amount,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS flag,
        'catalog' AS source_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
store_ret_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        d.d_year AS year,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS flag,
        'store_return' AS source_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE EXISTS (
        SELECT 1 FROM reason r WHERE r.r_reason_sk = sr.sr_reason_sk AND r.r_reason_desc LIKE '%damage%'
    )
    GROUP BY sr.sr_customer_sk, d.d_year
)
SELECT
    ca.customer_sk,
    ca.year,
    ca.total_amount,
    ca.flag,
    ca.source_type,
    (SELECT MAX(d2.d_year) FROM date_dim d2) AS current_max_year,
    CASE WHEN ca.customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_preferred_cust_flag = 'Y') THEN 'Preferred' ELSE 'Other' END AS customer_category
FROM (
    SELECT * FROM catalog_agg
    UNION
    SELECT * FROM store_ret_agg
) ca
WHERE ca.customer_sk NOT IN (
    SELECT c.c_customer_sk FROM customer c WHERE c.c_birth_year < 1950
)
ORDER BY ca.year DESC, ca.total_amount DESC
