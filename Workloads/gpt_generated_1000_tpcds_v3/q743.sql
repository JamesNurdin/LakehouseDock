WITH date_filtered AS (
    SELECT d_date_sk, d_year, d_date
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
      AND d_month_seq BETWEEN 1 AND 12
)
SELECT source,
       year,
       category,
       gender,
       COUNT(*) AS return_cnt,
       SUM(return_amount) AS total_return_amount,
       AVG(return_amount) AS avg_return_amount
FROM (
    SELECT 'store' AS source,
           d.d_year AS year,
           i.i_category AS category,
           cd.cd_gender AS gender,
           sr.sr_return_amt_inc_tax AS return_amount
    FROM store_returns sr
    JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE i.i_brand = 'Brand#12'
      AND cd.cd_marital_status = 'M'
      AND c.c_birth_month = 7
      AND sr.sr_return_amt_inc_tax > 100
    UNION ALL
    SELECT 'catalog' AS source,
           d.d_year AS year,
           i.i_category AS category,
           cd.cd_gender AS gender,
           cr.cr_return_amt_inc_tax AS return_amount
    FROM catalog_returns cr
    JOIN date_filtered d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE i.i_brand = 'Brand#12'
      AND cd.cd_marital_status = 'M'
      AND c.c_birth_month = 7
      AND cr.cr_return_amt_inc_tax > 100
) AS combined
GROUP BY source, year, category, gender
ORDER BY source, total_return_amount DESC
LIMIT 100
