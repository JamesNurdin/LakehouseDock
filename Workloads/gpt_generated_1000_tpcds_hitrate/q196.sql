/*
  Goal: Combine high‑value catalog returns of Dr. customers in California (where the return reason mentions price) with web page activity of customers who have never returned an item, then rank the combined rows by the numeric metric (return amount or page character count).
*/
WITH return_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        'return' AS activity_type,
        cr.cr_return_amount AS metric,
        r.r_reason_desc AS description
    FROM catalog_returns cr
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c
      ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE r.r_reason_desc LIKE '%price%'
      AND cc.cc_state = 'CA'
      AND c.c_salutation = 'Dr.'
      AND cr.cr_return_amount > (
          SELECT avg(cr2.cr_return_amount)
          FROM catalog_returns cr2
          WHERE cr2.cr_reason_sk = r.r_reason_sk
      )
),
web_page_data AS (
    SELECT
        c.c_customer_id AS customer_id,
        'web_page' AS activity_type,
        wp.wp_char_count AS metric,
        wp.wp_url AS description
    FROM web_page wp
    JOIN customer c
      ON wp.wp_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_returning_customer_sk = c.c_customer_sk
      )
)
SELECT *
FROM return_data
UNION ALL
SELECT *
FROM web_page_data
ORDER BY metric DESC
LIMIT 100
