WITH sales_agg AS (
    SELECT
        i.i_manufact,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(ss.ss_net_paid) AS cust_net_paid,
        COUNT(*) AS cust_sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '@.*\\.edu')
      AND i.i_item_desc LIKE '%BRUSH%'
    GROUP BY
        i.i_manufact,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address
)
SELECT
    i_manufact,
    concat(c_first_name, ' ', c_last_name) AS full_name,
    regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain,
    substring(c_email_address, 1, 5) AS email_prefix,
    cust_net_paid,
    cust_sales_cnt,
    rank() OVER (PARTITION BY i_manufact ORDER BY cust_net_paid DESC) AS revenue_rank
FROM sales_agg
ORDER BY i_manufact, revenue_rank
