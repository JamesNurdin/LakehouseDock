WITH filtered_returns AS (
    SELECT
        cr.cr_refunded_customer_sk,
        cr.cr_fee,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_order_number
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_fee > 30
      AND cr.cr_return_tax > 5
)
SELECT
    c.c_customer_id,
    c.c_birth_year,
    wp.wp_type,
    COUNT(fr.cr_order_number) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_fee) AS avg_fee,
    MIN(fr.cr_return_tax) AS min_tax,
    MAX(fr.cr_return_tax) AS max_tax
FROM filtered_returns fr
JOIN tpcds.customer c
  ON fr.cr_refunded_customer_sk = c.c_customer_sk
JOIN tpcds.web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_last_review_date BETWEEN 2452400 AND 2452600
  AND wp.wp_autogen_flag = 'N'
  AND wp.wp_rec_end_date = DATE '2001-09-02'
GROUP BY c.c_customer_id, c.c_birth_year, wp.wp_type
ORDER BY total_return_amount DESC
LIMIT 100
