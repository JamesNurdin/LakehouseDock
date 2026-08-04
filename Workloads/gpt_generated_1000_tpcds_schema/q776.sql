WITH ss AS (
    SELECT
        c.c_customer_id,
        d.d_date,
        ss.ss_net_paid,
        CASE
            WHEN regexp_like(s.s_store_name, '^Super.*') THEN 'SuperStore'
            ELSE 'OtherStore'
        END AS category,
        concat(s.s_store_name, '-', CAST(d.d_year AS varchar)) AS identifier,
        LAG(ss.ss_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS prev_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_store_sk IN (
            SELECT s2.s_store_sk
            FROM store s2
            WHERE s2.s_state LIKE 'C%'
        )
      AND regexp_like(s.s_store_name, '^Super|^Store')
),
ws AS (
    SELECT
        c.c_customer_id,
        d.d_date,
        ws.ws_net_paid,
        CASE
            WHEN regexp_like(wp.wp_url, '\\.com$') THEN 'ComSite'
            ELSE 'OtherSite'
        END AS category,
        concat(substr(wp.wp_url, 1, 5), '-SITE') AS identifier,
        LAG(ws.ws_net_paid) OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date) AS prev_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_warehouse_sk IN (
            SELECT w.w_warehouse_sk
            FROM warehouse w
            WHERE w.w_city LIKE 'S%'
        )
      AND wp.wp_url LIKE '%example%'
)
SELECT
    u.c_customer_id,
    u.d_date,
    u.net_paid,
    u.category,
    u.identifier,
    u.prev_net_paid
FROM (
    SELECT
        c_customer_id,
        d_date,
        ss_net_paid AS net_paid,
        category,
        identifier,
        prev_net_paid
    FROM ss
    UNION DISTINCT
    SELECT
        c_customer_id,
        d_date,
        ws_net_paid AS net_paid,
        category,
        identifier,
        prev_net_paid
    FROM ws
) u
ORDER BY u.d_date DESC
LIMIT 100
