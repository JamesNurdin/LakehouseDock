WITH sampled_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_store_credit > 0
),
date_filtered AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year = 2000
      AND d_month_seq BETWEEN 1 AND 12
),
hd_filtered AS (
    SELECT hd_demo_sk, hd_income_band_sk, hd_vehicle_count
    FROM household_demographics
    WHERE hd_vehicle_count >= 2
      AND hd_income_band_sk = 5
),
promo_filtered AS (
    SELECT p_promo_sk, p_promo_name, p_discount_active, p_cost, p_start_date_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
      AND p_cost < 1000
),
web_filtered AS (
    SELECT wp_web_page_sk, wp_type, wp_image_count, wp_creation_date_sk
    FROM web_page
    WHERE wp_image_count >= 2
      AND wp_type IN ('article', 'advertisement')
),
agg1 AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        hd.hd_income_band_sk,
        p.p_promo_name,
        wp.wp_type,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt,
        ROW_NUMBER() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS row_num
    FROM sampled_returns sr
    JOIN date_filtered d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN hd_filtered hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN promo_filtered p
        ON sr.sr_returned_date_sk = p.p_start_date_sk
    JOIN web_filtered wp
        ON d.d_date_sk = wp.wp_creation_date_sk
    WHERE sr.sr_return_quantity BETWEEN 1 AND 10
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_name = p.p_promo_name
            AND p2.p_cost > 500
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY CUBE (d.d_year, d.d_month_seq, hd.hd_income_band_sk, p.p_promo_name, wp.wp_type)
),
agg2 AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        hd.hd_income_band_sk,
        p.p_promo_name,
        wp.wp_type,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt,
        ROW_NUMBER() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS row_num
    FROM sampled_returns sr
    JOIN date_filtered d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN hd_filtered hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN promo_filtered p
        ON sr.sr_returned_date_sk = p.p_start_date_sk
    JOIN web_filtered wp
        ON d.d_date_sk = wp.wp_creation_date_sk
    WHERE sr.sr_return_quantity BETWEEN 1 AND 10
      AND sr.sr_store_credit > 500
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_name = p.p_promo_name
            AND p2.p_cost > 500
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY CUBE (d.d_year, d.d_month_seq, hd.hd_income_band_sk, p.p_promo_name, wp.wp_type)
)
SELECT *
FROM agg1
EXCEPT
SELECT *
FROM agg2
ORDER BY total_return_amt DESC
LIMIT 100
