WITH returns_web AS (
  SELECT
    COALESCE(cr.cr_returned_date_sk, wp.wp_creation_date_sk) AS date_sk,
    COALESCE(d.d_date, DATE '2000-01-01') AS calendar_date,
    COALESCE(cr.cr_return_amount, DECIMAL '0.00') AS return_amount,
    COALESCE(wp.wp_image_count, 0) AS page_image_count,
    'ReturnsWeb' AS source
  FROM catalog_returns cr
  FULL OUTER JOIN web_page wp
    ON cr.cr_returned_date_sk = wp.wp_creation_date_sk
  LEFT JOIN date_dim d
    ON COALESCE(cr.cr_returned_date_sk, wp.wp_creation_date_sk) = d.d_date_sk
  WHERE
    (cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 1999
    ))
    OR wp.wp_image_count IN (
        SELECT wp2.wp_image_count
        FROM web_page wp2
        WHERE wp2.wp_type = 'ad' AND wp2.wp_image_count IS NOT NULL
    )
),
returns_only AS (
  SELECT
    cr.cr_returned_date_sk AS date_sk,
    d.d_date AS calendar_date,
    cr.cr_return_amount AS return_amount,
    0 AS page_image_count,
    'ReturnsOnly' AS source
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE EXISTS (
    SELECT 1
    FROM customer_address ca
    WHERE ca.ca_address_sk = cr.cr_refunded_addr_sk
      AND ca.ca_zip LIKE '75%'
  )
)
SELECT
  date_sk,
  calendar_date,
  return_amount,
  page_image_count,
  source
FROM returns_web
UNION ALL
SELECT
  date_sk,
  calendar_date,
  return_amount,
  page_image_count,
  source
FROM returns_only
ORDER BY calendar_date DESC, return_amount DESC
