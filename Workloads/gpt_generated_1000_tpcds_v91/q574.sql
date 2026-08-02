WITH sr_c AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        td.t_hour,
        td.t_minute,
        td.t_second,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address
    FROM store_returns sr
    FULL OUTER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
)
SELECT
    COALESCE(sr_c.t_hour, -1) AS hour_of_day,
    CASE
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 0 AND 5 THEN 'Late Night'
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'No Return'
    END AS time_bucket,
    CASE
        WHEN sr_c.s_store_name LIKE 'Store %' THEN 'StorePrefix'
        WHEN sr_c.s_store_name LIKE '%Outlet%' THEN 'Outlet'
        ELSE 'OtherStore'
    END AS store_name_category,
    CASE
        WHEN sr_c.c_first_name IS NOT NULL AND regexp_like(sr_c.c_first_name, '^A') THEN 'FirstNameStartsWithA'
        WHEN sr_c.c_last_name IS NOT NULL AND regexp_like(sr_c.c_last_name, 'son$') THEN 'LastNameEndsWithSon'
        ELSE 'Other'
    END AS name_category,
    SUBSTR(sr_c.ca_city, 1, 3) AS city_prefix,
    CONCAT(COALESCE(sr_c.c_first_name, ''), ' ', COALESCE(sr_c.c_last_name, '')) AS customer_full_name,
    COUNT(DISTINCT sr_c.sr_returned_date_sk) AS distinct_return_dates,
    SUM(COALESCE(sr_c.sr_net_loss, 0)) AS total_net_loss,
    SUM(COALESCE(sr_c.sr_return_amt, 0)) AS total_return_amount
FROM sr_c
WHERE
    (sr_c.s_store_name LIKE 'Store %' OR sr_c.s_store_name LIKE '%Outlet%')
    AND (sr_c.t_second % 2 = 0 OR sr_c.t_second IS NULL)
    AND (sr_c.ca_city LIKE 'New%' OR sr_c.ca_city IS NULL)
GROUP BY
    COALESCE(sr_c.t_hour, -1),
    CASE
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 0 AND 5 THEN 'Late Night'
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN COALESCE(sr_c.t_hour, -1) BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'No Return'
    END,
    CASE
        WHEN sr_c.s_store_name LIKE 'Store %' THEN 'StorePrefix'
        WHEN sr_c.s_store_name LIKE '%Outlet%' THEN 'Outlet'
        ELSE 'OtherStore'
    END,
    CASE
        WHEN sr_c.c_first_name IS NOT NULL AND regexp_like(sr_c.c_first_name, '^A') THEN 'FirstNameStartsWithA'
        WHEN sr_c.c_last_name IS NOT NULL AND regexp_like(sr_c.c_last_name, 'son$') THEN 'LastNameEndsWithSon'
        ELSE 'Other'
    END,
    SUBSTR(sr_c.ca_city, 1, 3),
    CONCAT(COALESCE(sr_c.c_first_name, ''), ' ', COALESCE(sr_c.c_last_name, ''))
HAVING
    SUM(COALESCE(sr_c.sr_net_loss, 0)) > 1000
ORDER BY
    total_net_loss DESC,
    hour_of_day
LIMIT 100
