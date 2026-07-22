WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_returning_customer_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    WHERE regexp_like(cp.cp_description, '\\d{3}')
      AND c.c_email_address LIKE '%gmail.com'
)
SELECT
    d.d_year,
    d.d_month_seq,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    SUBSTRING(cp.cp_type FROM 1 FOR 3) AS cp_type_prefix,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(fr.cr_return_quantity) AS total_return_quantity,
    SUM(fr.cr_net_loss) AS total_net_loss
FROM filtered_returns fr
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON fr.cr_returning_customer_sk = c.c_customer_sk
GROUP BY
    d.d_year,
    d.d_month_seq,
    CONCAT(cc.cc_city, ', ', cc.cc_state),
    SUBSTRING(cp.cp_type FROM 1 FOR 3)
ORDER BY total_net_loss DESC
LIMIT 100
