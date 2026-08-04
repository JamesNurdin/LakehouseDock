WITH
    cs_match AS (
        SELECT cs_bill_customer_sk AS cust_sk,
               cs_net_paid,
               cs_promo_sk
        FROM catalog_sales
        JOIN promotion ON cs_promo_sk = p_promo_sk
        WHERE regexp_like(p_promo_name, '^Summer')
          AND p_channel_details LIKE '%discount%'
    ),
    ws_match AS (
        SELECT ws_bill_customer_sk AS cust_sk,
               ws_net_paid,
               ws_promo_sk
        FROM web_sales
        JOIN promotion ON ws_promo_sk = p_promo_sk
        WHERE regexp_like(p_promo_name, '^Summer')
          AND p_channel_details LIKE '%discount%'
    ),
    union_cust_sales AS (
        SELECT cust_sk,
               SUM(net_paid) AS total_paid
        FROM (
            SELECT cust_sk, cs_net_paid AS net_paid FROM cs_match
            UNION DISTINCT
            SELECT cust_sk, ws_net_paid AS net_paid FROM ws_match
        ) u
        GROUP BY cust_sk
    ),
    intersect_cust AS (
        SELECT ss_customer_sk AS cust_sk
        FROM store_sales
        WHERE ss_quantity > 5
        INTERSECT
        SELECT sr_customer_sk FROM store_returns
        WHERE sr_return_quantity > 0
    ),
    sales_returns_full AS (
        SELECT ss.ss_customer_sk,
               ss.ss_net_paid,
               sr.sr_return_amt_inc_tax
        FROM store_sales ss
        FULL OUTER JOIN store_returns sr
          ON ss.ss_ticket_number = sr.sr_ticket_number
    ),
    sales_customer_right AS (
        SELECT c.c_customer_sk AS c_customer_sk,
               c.c_email_address,
               ss.ss_net_paid
        FROM store_sales ss
        RIGHT OUTER JOIN customer c
          ON ss.ss_customer_sk = c.c_customer_sk
    )
SELECT
    scr.c_email_address,
    substring(scr.c_email_address FROM 1 FOR 5) AS email_prefix,
    concat(substring(scr.c_email_address FROM 1 FOR 5), '_', CAST(ucs.total_paid AS varchar)) AS email_summary,
    regexp_extract(scr.c_email_address, '([^@]+)') AS email_user,
    ucs.total_paid,
    srf.ss_net_paid,
    srf.sr_return_amt_inc_tax,
    CASE WHEN regexp_like(scr.c_email_address, '.*@example\\.com$') THEN 'ExampleDomain' ELSE 'OtherDomain' END AS email_domain_flag
FROM union_cust_sales ucs
JOIN sales_customer_right scr
  ON ucs.cust_sk = scr.c_customer_sk
LEFT JOIN intersect_cust ic
  ON ucs.cust_sk = ic.cust_sk
LEFT JOIN sales_returns_full srf
  ON ucs.cust_sk = srf.ss_customer_sk
WHERE ic.cust_sk IS NOT NULL
ORDER BY ucs.total_paid DESC
LIMIT 100
