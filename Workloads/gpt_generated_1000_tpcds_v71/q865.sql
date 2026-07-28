/*
Goal: Compare total return amounts per customer from store and catalog channels, categorize the amounts, attach the customer's income lower bound, and list the source of the return. The query uses UNION ALL to combine the two channels, includes a CASE expression, DISTINCT, a scalar subquery, and an EXISTS filter, and returns the first 100 rows.
*/
WITH store_ret AS (
    SELECT
        c.c_customer_id,
        SUM(sr.sr_return_amt) AS total_return_amt,
        CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_category,
        (
            SELECT ib.ib_lower_bound
            FROM household_demographics hd
            JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
            WHERE hd.hd_demo_sk = sr.sr_hdemo_sk
        ) AS income_lower_bound
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM store s2
          WHERE s2.s_store_sk = sr.sr_store_sk
            AND s2.s_city = 'Seattle'
      )
    GROUP BY c.c_customer_id, sr.sr_hdemo_sk
),
catalog_ret AS (
    SELECT
        c.c_customer_id,
        SUM(cr.cr_return_amount) AS total_return_amt,
        CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS return_category,
        (
            SELECT ib.ib_lower_bound
            FROM household_demographics hd
            JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
            WHERE hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
        ) AS income_lower_bound
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE w.w_state = 'CA'
      AND r.r_reason_desc LIKE '%damage%'
    GROUP BY c.c_customer_id, cr.cr_refunded_hdemo_sk
)
SELECT DISTINCT
    sr.c_customer_id,
    sr.total_return_amt,
    sr.return_category,
    sr.income_lower_bound,
    'Store' AS source
FROM store_ret sr
UNION ALL
SELECT DISTINCT
    cr.c_customer_id,
    cr.total_return_amt,
    cr.return_category,
    cr.income_lower_bound,
    'Catalog' AS source
FROM catalog_ret cr
LIMIT 100
