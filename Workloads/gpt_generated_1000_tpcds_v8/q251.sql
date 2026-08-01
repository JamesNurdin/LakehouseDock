WITH sampled_returns AS (
   SELECT *
   FROM store_returns TABLESAMPLE BERNOULLI (10)
   WHERE sr_return_tax > 20
),
filtered_join AS (
   SELECT
       c.c_customer_id,
       cd.cd_gender,
       cd.cd_marital_status,
       sr.sr_return_amt
   FROM sampled_returns sr
   RIGHT OUTER JOIN customer_demographics cd
       ON sr.sr_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN customer c
       ON sr.sr_customer_sk = c.c_customer_sk
   WHERE
       cd.cd_gender = 'M'
       AND c.c_birth_year BETWEEN 1950 AND 1960
       AND EXISTS (
           SELECT 1 FROM store_returns sr2
           WHERE sr2.sr_customer_sk = c.c_customer_sk
             AND sr2.sr_return_amt > 100
             AND sr2.sr_return_tax > 30
       )
),
aggregated AS (
   SELECT
       c_customer_id,
       cd_gender,
       cd_marital_status,
       SUM(sr_return_amt) AS total_return_amt,
       COUNT(*) AS return_cnt
   FROM filtered_join
   GROUP BY c_customer_id, cd_gender, cd_marital_status
   HAVING SUM(sr_return_amt) > 500
)
SELECT
    c_customer_id,
    cd_gender,
    cd_marital_status,
    total_return_amt,
    return_cnt,
    RANK() OVER (PARTITION BY cd_gender ORDER BY total_return_amt DESC) AS gender_return_rank,
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS overall_return_rank
FROM aggregated
ORDER BY total_return_amt DESC
LIMIT 100
