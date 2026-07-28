WITH recent_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2020
)
SELECT
    'store' AS entity_type,
    s.s_store_id AS entity_id,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_amount
FROM recent_dates d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE s.s_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE hd.hd_demo_sk = ss.ss_hdemo_sk
          AND ib.ib_lower_bound >= 50000
      )
GROUP BY s.s_store_id, d.d_year

UNION ALL

SELECT
    'web' AS entity_type,
    wp.wp_url AS entity_id,
    d.d_year,
    SUM(wr.wr_return_amt) * -1 AS total_amount
FROM recent_dates d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_type = 'content'
  AND wp.wp_url IN (
        SELECT wp_inner.wp_url
        FROM web_page wp_inner
        WHERE wp_inner.wp_char_count > 5000
      )
GROUP BY wp.wp_url, d.d_year

ORDER BY entity_type, total_amount DESC
LIMIT 100
