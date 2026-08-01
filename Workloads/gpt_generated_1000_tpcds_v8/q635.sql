WITH
  sr_cust AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        d.d_year,
        CASE WHEN sr.sr_return_amt > 100 THEN 'high' ELSE 'low' END AS return_category,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM store_returns sr
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk   = cd.cd_demo_sk
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(c.c_email_address, '.*@.*\\.com')
  ),

  web_page_dim AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_customer_sk,
        wp.wp_type,
        wp.wp_url,
        wp.wp_image_count,
        d.d_year,
        CASE WHEN wp.wp_image_count > 3 THEN 'many_images' ELSE 'few_images' END AS image_category,
        concat('Page-', wp.wp_web_page_id) AS page_label
    FROM web_page wp
    LEFT JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_type LIKE 'ad%'
  ),

  date_web_full AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        wp.wp_web_page_sk,
        wp.wp_type
    FROM date_dim d
    FULL OUTER JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  )

SELECT
    sr.sr_customer_sk,
    sr.full_name,
    sr.email_domain,
    sr.return_category,
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.image_category,
    wp.page_label,
    sr.d_year AS return_year,
    wp.d_year AS page_year
FROM sr_cust sr
RIGHT OUTER JOIN web_page_dim wp
  ON sr.sr_customer_sk = wp.wp_customer_sk
WHERE NOT EXISTS (
    SELECT 1 FROM store_returns sr2
    WHERE sr2.sr_customer_sk = sr.sr_customer_sk
      AND sr2.sr_return_amt > 200
)
UNION
SELECT
    NULL AS sr_customer_sk,
    NULL AS full_name,
    NULL AS email_domain,
    NULL AS return_category,
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.image_category,
    wp.page_label,
    NULL AS return_year,
    wp.d_year AS page_year
FROM web_page_dim wp
WHERE NOT EXISTS (
    SELECT 1 FROM sr_cust sr WHERE sr.sr_customer_sk = wp.wp_customer_sk
)
UNION
SELECT
    NULL AS sr_customer_sk,
    NULL AS full_name,
    NULL AS email_domain,
    NULL AS return_category,
    fw.wp_web_page_sk,
    fw.wp_type,
    NULL AS image_category,
    NULL AS page_label,
    NULL AS return_year,
    fw.d_year AS page_year
FROM date_web_full fw
WHERE fw.wp_web_page_sk IS NULL
ORDER BY page_year DESC, wp_type
OFFSET 20 ROWS FETCH NEXT 100 ROWS ONLY
