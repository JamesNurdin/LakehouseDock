WITH filtered_returns AS (
    SELECT
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(CAST(cr.cr_fee AS VARCHAR), '^\\d+\\.\\d{2}$')
    GROUP BY cr.cr_refunded_customer_sk, cr.cr_item_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    CONCAT(c.c_email_address, '_', CAST(fr.total_return_amount AS VARCHAR)) AS email_return_key,
    i.i_product_name,
    i.i_item_desc,
    fr.total_return_amount,
    fr.return_cnt,
    r.r_reason_desc
FROM filtered_returns fr
JOIN customer c
  ON fr.customer_sk = c.c_customer_sk
JOIN item i
  ON fr.item_sk = i.i_item_sk
JOIN catalog_returns cr2
  ON cr2.cr_refunded_customer_sk = fr.customer_sk
 AND cr2.cr_item_sk = fr.item_sk
JOIN reason r
  ON cr2.cr_reason_sk = r.r_reason_sk
WHERE regexp_like(i.i_item_desc, '(?i)advanced|pro')
  AND i.i_product_name LIKE '%Bike%'
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
          AND p.p_start_date_sk = (
                SELECT MAX(d2.d_date_sk)
                FROM date_dim d2
                WHERE d2.d_year = 2001
          )
      )
ORDER BY fr.total_return_amount DESC
LIMIT 100
