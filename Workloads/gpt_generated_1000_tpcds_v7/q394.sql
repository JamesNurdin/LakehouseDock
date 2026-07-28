WITH return_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        i.i_brand,
        ca.ca_street_name,
        ca.ca_suite_number,
        regexp_extract(ca.ca_suite_number, '(\\d+)', 1) AS suite_number
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE ca.ca_street_name LIKE '%Park%'
      AND regexp_like(ca.ca_suite_number, '^Suite [A-Z]')
)
SELECT
    i_brand,
    suite_number,
    COUNT(*) AS returns_cnt,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    concat(i_brand, '-', suite_number) AS brand_suite_key
FROM return_data
GROUP BY i_brand, suite_number
ORDER BY total_net_loss DESC
LIMIT 10
