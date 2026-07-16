SELECT
    d.d_year,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS order_count,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MAX(cr.cr_return_quantity) AS max_return_quantity,
    COUNT(DISTINCT ca_refunded.ca_address_id) AS distinct_refunded_addresses,
    COUNT(DISTINCT ca_returning.ca_address_id) AS distinct_returning_addresses,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(wp.wp_image_count) AS total_image_count
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
   AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND ca_refunded.ca_country = 'United States'
GROUP BY d.d_year, s.s_state
ORDER BY total_net_loss DESC
LIMIT 100
