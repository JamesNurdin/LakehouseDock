WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_zip,
        substring(ca.ca_zip, 1, 3) AS zip_prefix,
        c.c_email_address,
        cc.cc_name AS call_center_name,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(*) AS order_count
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        regexp_like(c.c_email_address, '@example\\.com$')
        AND ca.ca_zip LIKE '9%'
        AND regexp_like(p.p_promo_name, '(?i)discount')
    GROUP BY
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name),
        ca.ca_zip,
        substring(ca.ca_zip, 1, 3),
        c.c_email_address,
        cc.cc_name
),
avg_profit AS (
    SELECT avg(total_net_profit) AS avg_profit FROM customer_sales
)
SELECT
    cs.full_name,
    cs.ca_zip,
    cs.zip_prefix,
    cs.c_email_address,
    cs.call_center_name,
    cs.total_net_paid,
    cs.total_net_profit,
    cs.order_count
FROM customer_sales cs
CROSS JOIN avg_profit ap
WHERE cs.total_net_profit > ap.avg_profit
ORDER BY cs.total_net_profit DESC
LIMIT 100
