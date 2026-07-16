SELECT
    wp.wp_type AS web_page_type,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    RANK() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS return_amount_rank
FROM
    catalog_returns cr
JOIN
    web_page wp
      ON cr.cr_returning_customer_sk = wp.wp_customer_sk
WHERE
    cr.cr_return_amount > 0
    AND cr.cr_return_quantity >= 1
    AND wp.wp_type IS NOT NULL
    AND cr.cr_returning_customer_sk IN (6114601, 7882809, 502311, 471681, 7633027)
GROUP BY
    wp.wp_type
HAVING
    COUNT(*) >= 10
ORDER BY
    total_return_amount DESC
LIMIT 20
