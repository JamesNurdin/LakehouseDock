WITH
  city_zip_prefixes AS (
    SELECT DISTINCT
      ca.ca_city AS city,
      regexp_extract(ca.ca_zip, '(\\d{3})', 1) AS zip_prefix
    FROM tpcds.customer_address ca
    WHERE regexp_like(ca.ca_city, '^A')
  ),
  store_agg AS (
    SELECT
      'store_sales' AS src,
      ca.ca_address_sk AS address_sk,
      ca.ca_city AS city,
      ca.ca_zip AS zip,
      SUM(ss.ss_net_paid) AS total_amount,
      COUNT(*) AS txn_count
    FROM tpcds.store_sales ss
    JOIN tpcds.customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^A')
      AND ca.ca_zip LIKE '9%'
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_zip
  ),
  web_ret_agg AS (
    SELECT
      'web_returns' AS src,
      ca.ca_address_sk AS address_sk,
      ca.ca_city AS city,
      ca.ca_zip AS zip,
      SUM(wr.wr_return_amt) AS total_amount,
      COUNT(*) AS txn_count
    FROM tpcds.web_returns wr
    JOIN tpcds.web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^A')
      AND ca.ca_zip LIKE '9%'
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_zip
  ),
  combined AS (
    SELECT src, address_sk, city, zip, total_amount, txn_count FROM store_agg
    UNION ALL
    SELECT src, address_sk, city, zip, total_amount, txn_count FROM web_ret_agg
  )
SELECT
  combined.src,
  combined.city,
  combined.zip,
  combined.total_amount,
  combined.txn_count,
  czp.zip_prefix,
  concat(combined.city, '-', combined.src) AS city_src_label,
  (
    SELECT MAX(ss2.ss_net_paid)
    FROM tpcds.store_sales ss2
    WHERE ss2.ss_addr_sk = combined.address_sk
      AND ss2.ss_net_paid < combined.total_amount
  ) AS max_lower_net_paid,
  ROW_NUMBER() OVER (ORDER BY combined.total_amount DESC) AS rn
FROM combined
JOIN city_zip_prefixes czp
  ON combined.city = czp.city
ORDER BY combined.total_amount DESC
LIMIT 100
