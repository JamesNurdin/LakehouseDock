WITH web_daily AS (
        SELECT d.d_year,
               d.d_date,
               SUM(ws.ws_net_paid_inc_tax) AS web_rev
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY d.d_year, d.d_date
    ),
    store_daily AS (
        SELECT d.d_year,
               d.d_date,
               SUM(ss.ss_net_paid_inc_tax) AS store_rev
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY d.d_year, d.d_date
    )
SELECT key,
       total_rev,
       rn,
       source,
       max_year_date
FROM (
        SELECT CAST(d.d_date AS varchar) AS key,
               COALESCE(w.web_rev, 0) + COALESCE(s.store_rev, 0) AS total_rev,
               ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY COALESCE(w.web_rev, 0) + COALESCE(s.store_rev, 0) DESC) AS rn,
               'date' AS source,
               (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2002) AS max_year_date
        FROM date_dim d
        LEFT JOIN web_daily w ON d.d_date = w.d_date
        LEFT JOIN store_daily s ON d.d_date = s.d_date
        CROSS JOIN (
            SELECT r_reason_id
            FROM reason
            WHERE r_reason_id LIKE 'AAAA%'
        ) r
        WHERE d.d_year = 2002
        AND COALESCE(w.web_rev, 0) + COALESCE(s.store_rev, 0) > 1000
    ) a
UNION
SELECT key,
       total_rev,
       rn,
       source,
       max_year_date
FROM (
        SELECT c.c_customer_id AS key,
               SUM(ws.ws_net_paid_inc_tax) AS total_rev,
               ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rn,
               'customer' AS source,
               (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2002) AS max_year_date
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
        GROUP BY c.c_customer_id
        HAVING SUM(ws.ws_net_paid_inc_tax) > 5000
           AND c.c_customer_id NOT IN (
               SELECT DISTINCT c2.c_customer_id
               FROM web_returns wr
               JOIN customer c2 ON wr.wr_refunded_customer_sk = c2.c_customer_sk
           )
    ) b
ORDER BY total_rev DESC,
         source
LIMIT 100
