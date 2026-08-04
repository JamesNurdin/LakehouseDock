WITH reason_filtered AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%size%'
)
SELECT date_key, amount, status, cnt
FROM (
    SELECT
        cr.cr_returned_date_sk AS date_key,
        cr.cr_return_amount AS amount,
        CASE WHEN cr.cr_return_amount > 0 THEN 'Profit' ELSE 'Loss' END AS status,
        (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_order_number = cr.cr_order_number) AS cnt
    FROM catalog_returns cr
    JOIN reason_filtered r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%size%')
) 
UNION ALL
SELECT date_key, amount, status, cnt
FROM (
    SELECT
        ws.ws_sold_date_sk AS date_key,
        ws.ws_ext_sales_price AS amount,
        CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS status,
        (SELECT COUNT(*) FROM web_sales ws2 WHERE ws2.ws_order_number = ws.ws_order_number) AS cnt
    FROM web_sales ws
    RIGHT OUTER JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE wsite.web_city IN (
        SELECT DISTINCT web_city FROM web_site WHERE web_street_name = 'Sycamore'
    )
) 
ORDER BY amount DESC, status
LIMIT 100
