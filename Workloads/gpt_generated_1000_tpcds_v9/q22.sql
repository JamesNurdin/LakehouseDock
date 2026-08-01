WITH
  store_agg AS (
    SELECT
      ss_customer_sk,
      COUNT(*) AS store_txn_cnt,
      SUM(ss_net_profit) AS store_net_profit,
      SUM(ss_sales_price) AS store_sales_total
    FROM store_sales
    WHERE ss_sales_price > 0
    GROUP BY ss_customer_sk
  ),
  web_agg AS (
    SELECT
      ws_bill_customer_sk AS customer_sk,
      COUNT(*) AS web_txn_cnt,
      SUM(ws_net_profit) AS web_net_profit,
      SUM(ws_sales_price) AS web_sales_total
    FROM web_sales
    WHERE ws_sales_price > 10
    GROUP BY ws_bill_customer_sk
  ),
  customer_info AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      REGEXP_EXTRACT(c.c_email_address, '@([^\\.]+)\\.[a-z]+$', 1) AS email_domain,
      CASE
        WHEN REGEXP_LIKE(c.c_email_address, '^.*@[^@]+\\.com$') THEN 'com'
        ELSE NULL
      END AS email_tld
    FROM customer c
    WHERE c.c_email_address IS NOT NULL
  ),
  web_page_agg AS (
    SELECT
      wp_customer_sk AS customer_sk,
      COUNT(*) AS page_cnt,
      SUM(CASE WHEN REGEXP_LIKE(wp_url, '^http://www\\.foo\\.com') THEN 1 ELSE 0 END) AS foo_url_cnt,
      MAX(CASE WHEN REGEXP_LIKE(wp_url, '^http://www\\.foo\\.com') THEN wp_url END) AS example_foo_url
    FROM web_page
    GROUP BY wp_customer_sk
  )
SELECT
  COALESCE(sa.ss_customer_sk, wa.customer_sk) AS customer_sk,
  ci.c_email_address,
  ci.email_domain,
  sa.store_txn_cnt,
  sa.store_sales_total,
  wa.web_txn_cnt,
  wa.web_sales_total,
  (COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0)) AS total_net_profit,
  CASE
    WHEN ci.c_email_address LIKE '%@example.com' THEN 'Example Domain'
    ELSE 'Other Domain'
  END AS email_classification,
  CONCAT('Customer_', CAST(COALESCE(sa.ss_customer_sk, wa.customer_sk) AS VARCHAR)) AS customer_label,
  wp.page_cnt,
  wp.foo_url_cnt,
  wp.example_foo_url
FROM store_agg sa
FULL OUTER JOIN web_agg wa
  ON sa.ss_customer_sk = wa.customer_sk
LEFT JOIN customer_info ci
  ON ci.c_customer_sk = COALESCE(sa.ss_customer_sk, wa.customer_sk)
LEFT JOIN web_page_agg wp
  ON wp.customer_sk = COALESCE(sa.ss_customer_sk, wa.customer_sk)
WHERE REGEXP_LIKE(ci.c_email_address, '.*@([a-zA-Z0-9.-]+)\\.(com|org|net)$')
  AND ci.c_email_address LIKE '%@%'
ORDER BY total_net_profit DESC
LIMIT 100
