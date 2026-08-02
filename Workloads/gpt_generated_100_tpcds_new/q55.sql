WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        ca.ca_city,
        ca.ca_zip
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_returned_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_current_day = 'N'
    )
      AND regexp_like(ca.ca_city, '^San')
      AND ca.ca_zip LIKE '9%'
)
SELECT
    wsit.web_name,
    substring(wsit.web_name, 1, 10) AS short_name,
    wsit.web_site_sk,
    d.d_year,
    SUM(fr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    CONCAT('Site-', CAST(wsit.web_site_sk AS VARCHAR)) AS site_label
FROM filtered_returns fr
JOIN date_dim d ON fr.cr_returned_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
WHERE wsit.web_class = 'Unknown'
GROUP BY
    wsit.web_name,
    substring(wsit.web_name, 1, 10),
    wsit.web_site_sk,
    d.d_year
ORDER BY
    total_return_amount DESC,
    wsit.web_name ASC
LIMIT 100
