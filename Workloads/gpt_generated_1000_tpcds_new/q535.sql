-- Goal: Analyze the combined impact of catalog and store returns across years and household buying potential, applying multiple filters, a sub‑query, sampling, CUBE aggregation, and UNNEST expansion, then deduplicate with UNION.

WITH sampled_store_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)  -- sample ~10% of rows for performance
)
SELECT
    d.d_year,
    hd.hd_buy_potential,
    SUM(cr.cr_return_amount)          AS total_return_amount,
    AVG(sr.sr_return_amt)             AS avg_store_return_amt,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_fee)                    AS min_fee,
    MAX(sr.sr_net_loss)               AS max_net_loss,
    SUM(t.value)                      AS total_quantity_fee_sum
FROM sampled_store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
CROSS JOIN UNNEST(
        ARRAY[CAST(cr.cr_return_quantity AS double), CAST(cr.cr_fee AS double)]
) AS t(value)
WHERE d.d_fy_quarter_seq = 15
  AND d.d_following_holiday = 'N'
  AND hd.hd_buy_potential = '>10000'
  AND cr.cr_store_credit > 100
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = 256
          AND cr2.cr_returned_date_sk = d.d_date_sk
    )
GROUP BY CUBE (d.d_year, hd.hd_buy_potential)

UNION DISTINCT

SELECT
    d.d_year,
    hd.hd_buy_potential,
    SUM(cr.cr_return_amount)          AS total_return_amount,
    AVG(sr.sr_return_amt)             AS avg_store_return_amt,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_fee)                    AS min_fee,
    MAX(sr.sr_net_loss)               AS max_net_loss,
    SUM(t.value)                      AS total_quantity_fee_sum
FROM sampled_store_returns sr
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
  AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
CROSS JOIN UNNEST(
        ARRAY[CAST(cr.cr_return_quantity AS double), CAST(cr.cr_fee AS double)]
) AS t(value)
WHERE d.d_fy_quarter_seq = 14
  AND d.d_following_holiday = 'Y'
  AND hd.hd_vehicle_count >= 2
  AND cr.cr_store_credit BETWEEN 20 AND 200
  AND sr.sr_return_amt > 50
GROUP BY CUBE (d.d_year, hd.hd_buy_potential)

ORDER BY total_return_amount DESC, d_year ASC, hd_buy_potential
LIMIT 100
