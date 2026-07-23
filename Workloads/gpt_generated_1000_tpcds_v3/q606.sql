WITH
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_quantity) AS catalog_qty,
        MAX(regexp_extract(p.p_channel_details, '(structures|common|available)', 1)) AS promo_keyword
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_channel_details, '(?i)structures|common|available')
    GROUP BY cs.cs_bill_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_details LIKE '%common%'
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country,
    ca.ca_city || ', ' || ca.ca_state AS city_state,
    cat.catalog_net_paid,
    web.web_net_paid,
    (cat.catalog_net_paid + web.web_net_paid) AS total_net_paid,
    (cat.catalog_qty + web.web_qty) AS total_quantity,
    cat.promo_keyword,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS return_count,
    (SELECT SUM(sr.sr_return_amt) FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk) AS total_return_amount,
    CASE
        WHEN regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$') THEN 'ExampleDomain'
        ELSE 'OtherDomain'
    END AS email_domain_category
FROM catalog_agg cat
JOIN web_agg web
    ON cat.cust_sk = web.cust_sk
JOIN customer c
    ON cat.cust_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE lower(ca.ca_city) LIKE 'f%'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_return_amt > 500
    )
ORDER BY total_net_paid DESC
LIMIT 100
