WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        c.c_first_name,
        c.c_last_name,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM tpcds.customer c
    WHERE c.c_email_address LIKE '%@example.com'
      AND regexp_like(c.c_email_address, '^.*@example\\.com$')
      AND c.c_first_name LIKE 'A%'
),
high_value_items AS (
    SELECT cs.cs_item_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
)
SELECT
    s.s_store_id,
    s.s_store_name,
    fc.email_domain,
    SUM(ss.ss_net_profit) AS total_net_profit,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM tpcds.store_sales ss
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN filtered_customers fc
    ON ss.ss_customer_sk = fc.c_customer_sk
JOIN tpcds.time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND ss.ss_item_sk IN (SELECT cs_item_sk FROM high_value_items)
GROUP BY
    s.s_store_id,
    s.s_store_name,
    fc.email_domain
ORDER BY total_net_profit DESC
LIMIT 100
