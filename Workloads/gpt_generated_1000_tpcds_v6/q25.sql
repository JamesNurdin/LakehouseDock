WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_fee,
        cr.cr_return_amount,
        cr.cr_return_quantity
    FROM catalog_returns cr
    WHERE cr.cr_fee > 20
      AND cr.cr_return_quantity >= 2
)
SELECT
    cc.cc_name,
    cc.cc_state,
    dr.d_year,
    CASE WHEN fr.cr_fee > 50 THEN 'High' ELSE 'Low' END AS fee_category,
    COUNT(DISTINCT fr.cr_refunded_customer_sk) AS unique_customers,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_fee) AS avg_fee,
    MIN(fr.cr_return_quantity) AS min_qty,
    MAX(fr.cr_return_quantity) AS max_qty
FROM filtered_returns fr
JOIN call_center cc
  ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dr
  ON fr.cr_returned_date_sk = dr.d_date_sk
JOIN customer cu
  ON fr.cr_refunded_customer_sk = cu.c_customer_sk
JOIN web_page wp
  ON wp.wp_customer_sk = cu.c_customer_sk
WHERE cc.cc_state = 'TN'
  AND cc.cc_hours = '8AM-4PM'
  AND dr.d_year = 2000
  AND cu.c_birth_country = 'United States'
  AND wp.wp_image_count >= 5
  AND wp.wp_type = 'product'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = cu.c_customer_sk
          AND cr2.cr_fee > 100
    )
GROUP BY
    cc.cc_name,
    cc.cc_state,
    dr.d_year,
    CASE WHEN fr.cr_fee > 50 THEN 'High' ELSE 'Low' END
ORDER BY total_return_amount DESC
LIMIT 100
