WITH filtered_catalog AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_net_loss,
        cr.cr_refunded_customer_sk,
        cp.cp_description
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cp.cp_description, '(?i)sale|discount')
)
SELECT
    sm.sm_carrier,
    CASE
        WHEN fc.cr_net_loss > 1000 THEN 'High'
        WHEN fc.cr_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    COUNT(*) AS return_cnt,
    SUM(fc.cr_net_loss) AS total_net_loss,
    ANY_VALUE(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS sample_customer_name,
    ANY_VALUE(REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1)) AS sample_email_domain
FROM filtered_catalog fc
JOIN ship_mode sm ON fc.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON fc.cr_refunded_customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
      AND wp.wp_url LIKE '%promo%'
)
GROUP BY
    sm.sm_carrier,
    CASE
        WHEN fc.cr_net_loss > 1000 THEN 'High'
        WHEN fc.cr_net_loss > 0 THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY total_net_loss DESC
LIMIT 100
