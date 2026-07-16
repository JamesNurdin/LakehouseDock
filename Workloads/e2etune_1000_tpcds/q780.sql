SELECT
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    ca.ca_state,
    c.c_birth_country,
    COUNT(*) AS cust_cnt,
    AVG(date_diff('day', dsales.d_date, dship.d_date)) AS avg_ship_delay,
    MIN(dsales.d_date) AS first_sales_date,
    MAX(dsales.d_date) AS last_sales_date
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    date_dim dsales ON c.c_first_sales_date_sk = dsales.d_date_sk
JOIN
    date_dim dship ON c.c_first_shipto_date_sk = dship.d_date_sk
JOIN
    store s ON s.s_closed_date_sk = dsales.d_date_sk
JOIN
    web_site ws ON ws.web_open_date_sk = dsales.d_date_sk
WHERE
    c.c_birth_month IN (4, 12)
    AND c.c_birth_country IN ('CHILE', 'MEXICO')
    AND dsales.d_year = 2005
GROUP BY
    s.s_store_id,
    s.s_store_name,
    ws.web_site_id,
    ws.web_name,
    ca.ca_state,
    c.c_birth_country
HAVING
    COUNT(*) >= 5
ORDER BY
    avg_ship_delay DESC
LIMIT 50
