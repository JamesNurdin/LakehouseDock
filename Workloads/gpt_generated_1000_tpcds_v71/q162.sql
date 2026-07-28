WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_warehouse_sk,
        cr.cr_net_loss,
        cr.cr_return_amount,
        ca.ca_state,
        ca.ca_city,
        d.d_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND regexp_like(ca.ca_city, '.*ville$')
)
SELECT
    w.w_warehouse_name,
    w.w_state,
    substr(fr.ca_city, 1, 3) AS city_prefix,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_count
FROM filtered_returns fr
JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM web_site ws
    JOIN date_dim d2 ON ws.web_open_date_sk = d2.d_date_sk
    WHERE ws.web_zip LIKE '9____'
      AND regexp_like(ws.web_zip, '^9[0-9]{4}$')
      AND d2.d_year = 2001
)
GROUP BY w.w_warehouse_name, w.w_state, substr(fr.ca_city, 1, 3)
ORDER BY total_net_loss DESC
LIMIT 100
