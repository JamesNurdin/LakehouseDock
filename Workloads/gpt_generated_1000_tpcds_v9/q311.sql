WITH intersected_orders AS (
    SELECT cr_order_number FROM catalog_returns
    WHERE cr_return_amount >= 100
    INTERSECT
    SELECT cr_order_number FROM catalog_returns
    WHERE cr_return_quantity > 2
)
SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_state,
    wp.wp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS num_returns,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM catalog_returns cr
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    wp.wp_web_page_id = 'AAAAAAAAMBAAAAAA'
    AND wp.wp_char_count BETWEEN 1000 AND 6000
    AND wp.wp_access_date_sk = 2452608
    AND ca.ca_street_name = 'Woodland Poplar'
    AND ca.ca_suite_number = 'Suite 390 '
    AND c.c_birth_year = 1975
    AND cr.cr_return_amount > 50.00
    AND cr.cr_return_quantity > 0
    AND cr.cr_order_number IN (SELECT cr_order_number FROM intersected_orders)
    AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_char_count > 5000
    )
GROUP BY GROUPING SETS (
    (c.c_first_name, c.c_last_name, ca.ca_state, wp.wp_type),
    (c.c_first_name, c.c_last_name, ca.ca_state),
    (c.c_first_name, c.c_last_name, wp.wp_type),
    (c.c_first_name, c.c_last_name),
    (ca.ca_state, wp.wp_type),
    (ca.ca_state),
    (wp.wp_type),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
