/*
  Goal: Identify the top stores (by total return amount) for the year 2002 where the store ZIP starts with '5' and the city name ends with "ville". The query demonstrates string processing (LIKE, REGEXP_LIKE, REGEXP_EXTRACT, CONCAT, SUBSTRING), uses a CTE, a correlated EXISTS subquery, a CASE expression for income classification, and aggregates the results.
*/
WITH recent_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        d.d_year
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    COUNT(*) AS returns_count,
    SUM(rr.sr_return_amt) AS total_return_amount,
    CASE
        WHEN ib.ib_lower_bound >= 50000 THEN 'High Income'
        ELSE 'Low Income'
    END AS income_category,
    REGEXP_EXTRACT(s.s_city, '^(.*)ville$', 1) AS city_without_ville,
    CONCAT(s.s_state, '-', s.s_zip) AS state_zip
FROM recent_returns rr
JOIN store s
    ON rr.sr_store_sk = s.s_store_sk
JOIN customer_demographics cd
    ON rr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON rr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE s.s_zip LIKE '5%'
  AND REGEXP_LIKE(s.s_city, '^[A-Z][a-z]+ville$')
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = rr.sr_customer_sk
          AND cs.cs_sold_date_sk = rr.sr_returned_date_sk
          AND cs.cs_ext_discount_amt > 100
    )
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    ib.ib_lower_bound,
    s.s_state,
    s.s_zip,
    REGEXP_EXTRACT(s.s_city, '^(.*)ville$', 1)
ORDER BY total_return_amount DESC
LIMIT 100
