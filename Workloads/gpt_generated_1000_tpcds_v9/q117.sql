WITH filtered_returns AS (
    SELECT 
        cr.cr_returned_date_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_quantity,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_tax > 30.00
      AND cr.cr_return_quantity >= 2
      AND cr.cr_return_amount > 100.00
      AND cr.cr_refunded_hdemo_sk IN (4008, 3089, 5112)
      AND EXISTS (
          SELECT 1
          FROM date_dim d2
          WHERE d2.d_date_sk = cr.cr_returned_date_sk
            AND d2.d_fy_year = 1909
            AND d2.d_weekend = 'N'
      )
)
SELECT
    d.d_year,
    d.d_quarter_name,
    COUNT(DISTINCT fr.cr_order_number) AS distinct_order_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM filtered_returns fr
JOIN date_dim d
  ON fr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 1909
  AND d.d_quarter_name = '1904Q3'
  AND d.d_current_quarter = 'Y'
GROUP BY d.d_year, d.d_quarter_name
ORDER BY total_return_amount DESC
LIMIT 100
