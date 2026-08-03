WITH store_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        s.s_store_sk,
        s.s_city,
        SUM(ss.ss_net_paid) AS store_net_paid
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_zip IN (
            SELECT w.w_zip
            FROM warehouse w
            WHERE w.w_city LIKE 'A%'
          )
      AND regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND s.s_geography_class LIKE '%Urban%'
    GROUP BY c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1),
        s.s_store_sk,
        s.s_city
),
web_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        ws.ws_web_site_sk,
        wsite.web_name,
        SUM(ws.ws_net_paid) AS web_net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_name LIKE 'Shop%'
      AND regexp_like(c.c_email_address, '^.*@example\\.com$')
    GROUP BY c.c_customer_sk,
        c.c_email_address,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1),
        ws.ws_web_site_sk,
        wsite.web_name
),
union_agg AS (
    SELECT c_customer_sk, email_domain, store_net_paid AS net_paid, 'store' AS src FROM store_agg
    UNION DISTINCT
    SELECT c_customer_sk, email_domain, web_net_paid AS net_paid, 'web' AS src FROM web_agg
),
intersect_keys AS (
    SELECT c_customer_sk FROM store_agg
    INTERSECT
    SELECT c_customer_sk FROM web_agg
),
full_join AS (
    SELECT
        COALESCE(sa.c_customer_sk, wa.c_customer_sk) AS customer_sk,
        sa.store_net_paid,
        wa.web_net_paid,
        sa.s_city,
        wa.web_name
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
        ON sa.c_customer_sk = wa.c_customer_sk
)
SELECT
    fj.customer_sk,
    fj.s_city,
    fj.web_name,
    fj.store_net_paid,
    fj.web_net_paid,
    u.total_net_paid,
    u.email_domain
FROM full_join fj
JOIN (
    SELECT c_customer_sk, email_domain, SUM(net_paid) AS total_net_paid
    FROM union_agg
    GROUP BY c_customer_sk, email_domain
) u
    ON fj.customer_sk = u.c_customer_sk
WHERE fj.customer_sk IN (SELECT c_customer_sk FROM intersect_keys)
ORDER BY total_net_paid DESC
LIMIT 100
