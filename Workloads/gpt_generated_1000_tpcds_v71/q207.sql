WITH refunds AS (
    SELECT ca.ca_country AS country,
           'refund_amount' AS metric,
           SUM(cr.cr_return_amount) AS value
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_reversed_charge > 100
    GROUP BY ca.ca_country
    HAVING SUM(cr.cr_return_amount) > 500
),
webpages AS (
    SELECT ca.ca_country AS country,
           'web_page_visits' AS metric,
           COUNT(wp.wp_web_page_sk) AS value
    FROM web_page wp
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE wp.wp_autogen_flag = 'Y'
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
    GROUP BY ca.ca_country
    HAVING COUNT(wp.wp_web_page_sk) > 10
)
SELECT country,
       metric,
       SUM(value) AS total_value
FROM (
    SELECT * FROM refunds
    UNION ALL
    SELECT * FROM webpages
) AS combined
GROUP BY country, metric
HAVING SUM(value) > 20
ORDER BY total_value DESC
LIMIT 100
