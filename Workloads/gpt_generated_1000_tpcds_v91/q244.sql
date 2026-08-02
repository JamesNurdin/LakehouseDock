WITH ws_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank_in_year
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year IN (1905, 1911)
      AND regexp_like(c.c_email_address, '.*@example\\.com$')
      AND c.c_last_name LIKE 'A%'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, d.d_year
),
cat_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        d.d_year,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_paid_inc_tax) DESC) AS rank_in_year
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year IN (1905, 1911)
      AND regexp_like(c.c_email_address, '.*@example\\.com$')
      AND c.c_last_name LIKE 'A%'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, d.d_year
),
unioned AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        d_year,
        total_net_paid,
        rank_in_year
    FROM ws_agg
    UNION
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        d_year,
        total_net_paid,
        rank_in_year
    FROM cat_agg
),
final_set AS (
    SELECT
        u.c_customer_sk,
        u.c_first_name,
        u.c_last_name,
        u.c_email_address,
        u.d_year,
        u.total_net_paid,
        u.rank_in_year,
        CONCAT(SUBSTRING(u.c_email_address FROM POSITION('@' IN u.c_email_address) + 1), '_domain') AS email_domain_tag,
        sm.sm_type,
        v.year_val
    FROM unioned u
    CROSS JOIN ship_mode sm
    CROSS JOIN (VALUES (1905), (1911)) AS v(year_val)
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = u.c_customer_sk
    )
      AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = u.c_customer_sk
    )
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    email_domain_tag,
    d_year,
    total_net_paid,
    rank_in_year,
    sm_type,
    year_val
FROM final_set
ORDER BY total_net_paid DESC, c_customer_sk
LIMIT 100
