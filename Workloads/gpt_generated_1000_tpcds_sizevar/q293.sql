WITH catalog_combo AS (
    SELECT
        c.c_email_address AS email,
        p.p_promo_name   AS promo,
        SUM(cs.cs_net_paid) AS total_paid
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND p.p_promo_name LIKE '%Summer%'
    GROUP BY c.c_email_address, p.p_promo_name
),
web_combo AS (
    SELECT
        c.c_email_address AS email,
        p.p_promo_name   AS promo,
        SUM(ws.ws_net_paid) AS total_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND p.p_promo_name LIKE '%Summer%'
    GROUP BY c.c_email_address, p.p_promo_name
),
common_combo AS (
    SELECT email, promo FROM catalog_combo
    INTERSECT
    SELECT email, promo FROM web_combo
),
union_part AS (
    SELECT
        email,
        promo,
        CASE WHEN strpos(promo, 'Clearance') > 0 THEN 'Clearance' ELSE 'Regular' END AS promo_type,
        SUM(total_paid) AS agg_paid
    FROM (
        SELECT email, promo, total_paid FROM catalog_combo
        UNION DISTINCT
        SELECT email, promo, total_paid FROM web_combo
    ) u
    GROUP BY
        email,
        promo,
        CASE WHEN strpos(promo, 'Clearance') > 0 THEN 'Clearance' ELSE 'Regular' END
)
SELECT
    cc.email,
    cc.promo,
    up.promo_type,
    up.agg_paid,
    regexp_extract(cc.email, '([^@]+)@', 1) AS user_part
FROM common_combo cc
JOIN union_part up ON cc.email = up.email AND cc.promo = up.promo
ORDER BY up.agg_paid DESC
LIMIT 100
