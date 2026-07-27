WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_returning_customer_sk,
        cr.cr_catalog_page_sk,
        cr.cr_net_loss,
        cp.cp_catalog_page_id,
        cp.cp_description,
        i.i_product_name,
        c.c_email_address,
        wp.wp_url
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE regexp_like(cp.cp_description, '(?i)electronic')
      AND wp.wp_url LIKE '%example.com%'
      AND c.c_email_address LIKE '%.com'
)
SELECT
    cp_catalog_page_id,
    cp_description,
    regexp_extract(i_product_name, '(\\d{3})', 1) AS product_code,
    concat(cp_catalog_page_id, '-', regexp_extract(i_product_name, '(\\d{3})', 1)) AS catalog_product_key,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM filtered
GROUP BY
    cp_catalog_page_id,
    cp_description,
    regexp_extract(i_product_name, '(\\d{3})', 1)
ORDER BY total_net_loss DESC
LIMIT 100
