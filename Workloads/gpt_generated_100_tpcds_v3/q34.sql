WITH sales AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        sum(ss.ss_net_profit) AS total_net_profit,
        count(DISTINCT ss.ss_ticket_number) AS total_transactions,
        sum(CASE WHEN p.p_promo_name LIKE '%Holiday%' THEN ss.ss_ext_sales_price ELSE 0 END) AS holiday_sales_amount
    FROM
        store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name
),
returns AS (
    SELECT
        c.c_customer_sk,
        sum(sr.sr_net_loss) AS total_net_loss,
        count(*) AS total_returns,
        sum(CASE WHEN regexp_like(r.r_reason_desc, '(?i)not') THEN 1 ELSE 0 END) AS returns_with_not_pattern
    FROM
        store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    s.c_customer_sk,
    s.full_name,
    s.c_email_address,
    regexp_extract(s.c_email_address, '@(.+)$', 1) AS email_domain,
    substr(s.c_email_address, 1, 5) AS email_prefix,
    s.total_net_profit,
    s.total_transactions,
    s.holiday_sales_amount,
    coalesce(r.total_net_loss, 0) AS total_net_loss,
    coalesce(r.total_returns, 0) AS total_returns,
    coalesce(r.returns_with_not_pattern, 0) AS returns_with_not_pattern
FROM
    sales s
    LEFT JOIN returns r ON s.c_customer_sk = r.c_customer_sk
WHERE
    regexp_like(s.c_email_address, '^[A-Za-z][A-Za-z0-9._%+-]+@example\\.com$')
ORDER BY
    s.total_net_profit DESC
LIMIT 100
