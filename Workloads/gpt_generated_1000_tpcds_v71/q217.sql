SELECT
    c.c_customer_id,
    dd.d_year AS event_year,
    'first_ship' AS event_type,
    ws.web_name AS website_name,
    (SELECT COUNT(*) FROM web_site ws_cnt WHERE ws_cnt.web_open_date_sk = dd.d_date_sk) AS open_site_count
FROM customer c
JOIN date_dim dd ON c.c_first_shipto_date_sk = dd.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
WHERE dd.d_year = 2001
  AND EXISTS (
        SELECT 1 FROM web_site ws2
        WHERE ws2.web_open_date_sk = dd.d_date_sk
          AND ws2.web_country = 'United States'
    )
UNION ALL
SELECT
    c.c_customer_id,
    dd.d_year AS event_year,
    'first_sales' AS event_type,
    ws.web_name AS website_name,
    (SELECT COUNT(*) FROM web_site ws_cnt WHERE ws_cnt.web_open_date_sk = dd.d_date_sk) AS open_site_count
FROM customer c
JOIN date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
WHERE dd.d_year = 2002
  AND EXISTS (
        SELECT 1 FROM web_site ws2
        WHERE ws2.web_open_date_sk = dd.d_date_sk
          AND ws2.web_country = 'United States'
    )
ORDER BY event_year DESC, event_type
LIMIT 100
