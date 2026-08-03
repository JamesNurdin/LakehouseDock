WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_return_time_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    GROUP BY sr_customer_sk, sr_return_time_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    wp.wp_url,
    t.t_hour,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(sr_agg.total_return_amt) AS total_store_return,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_net_loss) AS total_net_loss
FROM catalog_returns cr
JOIN time_dim t
    ON t.t_time_sk = cr.cr_returned_time_sk
JOIN customer c
    ON c.c_customer_sk = cr.cr_refunded_customer_sk
JOIN customer_address ca
    ON ca.ca_address_sk = cr.cr_refunded_addr_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN sr_agg
    ON sr_agg.sr_return_time_sk = t.t_time_sk
    AND sr_agg.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'MEXICO'
  AND ca.ca_zip = '90419'
  AND t.t_hour BETWEEN 9 AND 17
  AND c.c_customer_sk NOT IN (
        SELECT sr_customer_sk
        FROM store_returns
        WHERE sr_return_quantity = 0
    )
GROUP BY
    c.c_customer_id,
    ca.ca_city,
    wp.wp_url,
    t.t_hour
ORDER BY total_catalog_return DESC
LIMIT 100
