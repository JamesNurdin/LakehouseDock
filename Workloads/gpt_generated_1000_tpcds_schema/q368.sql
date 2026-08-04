WITH web_cust AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS cust_sk
    FROM web_sales ws
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%/sports/%'
      AND regexp_like(wp.wp_url, '^https?://[^/]+/sports/.*$')
),
store_cust AS (
    SELECT DISTINCT ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    WHERE ss.ss_net_paid > 1000
),
target_cust AS (
    SELECT cust_sk FROM web_cust
    EXCEPT
    SELECT cust_sk FROM store_cust
),
web_sales_agg AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           sum(ws.ws_ext_sales_price) AS total_web_sales,
           count(*) AS web_order_cnt
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk IN (SELECT cust_sk FROM target_cust)
    GROUP BY ws.ws_bill_customer_sk
)
SELECT
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_desc,
    ca.ca_city,
    ca.ca_state,
    wagg.total_web_sales,
    wagg.web_order_cnt
FROM target_cust tc
JOIN customer c
  ON tc.cust_sk = c.c_customer_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_sales_agg wagg
  ON tc.cust_sk = wagg.cust_sk
ORDER BY wagg.total_web_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
