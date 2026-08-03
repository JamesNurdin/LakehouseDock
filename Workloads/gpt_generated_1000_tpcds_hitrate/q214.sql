/*
Goal: Identify the stores with the highest net loss from product returns in 1998 for female customers with good credit ratings, group the results by store and month, rank the months by net loss per store, classify loss severity, and surface each store's overall highest single return amount using a LATERAL subquery.
*/
WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_cdemo_sk,
        SUM(sr.sr_return_amt)          AS total_return_amt,
        SUM(sr.sr_fee)                 AS total_fee,
        SUM(sr.sr_net_loss)            AS total_net_loss,
        COUNT(*)                       AS cnt_returns
    FROM store_returns sr
    WHERE sr.sr_return_amt > 50
      AND sr.sr_fee < 30
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk, sr.sr_cdemo_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    agg.sr_store_sk,
    agg.total_return_amt,
    agg.total_fee,
    agg.total_net_loss,
    CASE WHEN agg.total_net_loss > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    RANK() OVER (PARTITION BY agg.sr_store_sk ORDER BY agg.total_net_loss DESC) AS net_loss_rank,
    lt.max_return_amt AS top_single_return_amt
FROM sr_agg agg
JOIN date_dim d
    ON agg.sr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd
    ON agg.sr_cdemo_sk = cd.cd_demo_sk
-- LATERAL subquery to fetch the highest single return amount for the same store
LEFT JOIN LATERAL (
    SELECT MAX(sr2.sr_return_amt) AS max_return_amt
    FROM store_returns sr2
    WHERE sr2.sr_store_sk = agg.sr_store_sk
) lt ON true
WHERE d.d_year = 1998
  AND d.d_holiday = 'N'
  AND d.d_month_seq BETWEEN 1 AND 12
  AND cd.cd_gender = 'F'
  AND cd.cd_credit_rating = 'A'
  AND cd.cd_dep_count <= 2
  AND agg.sr_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_education_status = 'College'
    )
ORDER BY d.d_year, agg.sr_store_sk, net_loss_rank
LIMIT 100
