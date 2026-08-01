/*
Goal: Calculate total net loss and return amount from catalog returns for catalog pages whose description contains the words "premium" or "deluxe" during the second quarter of 2001. The result is grouped by the refunded customer's state and enriched with string‑processed categories (description and type), a concatenated state label, a city prefix, and a list of related web page URLs that were created on the same return date.
*/
SELECT
    d_ret.d_year,
    ca.ca_state,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    CASE
        WHEN regexp_like(cp.cp_description, '(?i)premium|deluxe') THEN 'PremiumOrDeluxe'
        ELSE 'Other'
    END AS description_category,
    CASE
        WHEN cp.cp_type LIKE 'PROMO%' THEN 'Promo'
        ELSE 'Standard'
    END AS type_category,
    CONCAT('State-', ca.ca_state) AS state_label,
    SUBSTR(ca.ca_city, 1, 3) AS city_prefix,
    ARRAY_AGG(DISTINCT wp.wp_url) AS related_web_urls
FROM
    catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
WHERE
    d_ret.d_year = 2001
    AND d_ret.d_qoy = 2
    AND cp.cp_type LIKE 'PROMO%'
    AND regexp_like(cp.cp_description, '(?i)premium|deluxe')
    AND ca.ca_state = 'CA'
    AND (wp.wp_url LIKE '%catalog%' OR wp.wp_url IS NULL)
GROUP BY
    d_ret.d_year,
    ca.ca_state,
    CASE WHEN regexp_like(cp.cp_description, '(?i)premium|deluxe') THEN 'PremiumOrDeluxe' ELSE 'Other' END,
    CASE WHEN cp.cp_type LIKE 'PROMO%' THEN 'Promo' ELSE 'Standard' END,
    CONCAT('State-', ca.ca_state),
    SUBSTR(ca.ca_city, 1, 3)
ORDER BY
    total_net_loss DESC,
    ca.ca_state
