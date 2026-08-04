WITH store_part AS (
   SELECT
     cd_demo_sk AS demo_key,
     cd_gender AS gender,
     SUM(ss_net_paid) AS total_net_paid,
     COUNT(ss_ticket_number) AS tx_cnt,
     CASE WHEN cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS descriptor,
     CAST(NULL AS varchar) AS zip_prefix
   FROM store_sales
   FULL OUTER JOIN customer_demographics
     ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
   WHERE cd_gender IS NOT NULL
     AND regexp_like(cd_gender, '^[MF]$')
   GROUP BY cd_demo_sk, cd_gender
),
web_part AS (
   SELECT
     ws_bill_cdemo_sk AS demo_key,
     cd_gender AS gender,
     SUM(ws_net_paid) AS total_net_paid,
     COUNT(ws_order_number) AS tx_cnt,
     CONCAT(web_site.web_city, ' - ', web_site.web_state) AS descriptor,
     l.zip_prefix AS zip_prefix
   FROM web_sales
   FULL OUTER JOIN web_site
     ON web_sales.ws_web_site_sk = web_site.web_site_sk
   FULL OUTER JOIN customer_demographics
     ON web_sales.ws_bill_cdemo_sk = customer_demographics.cd_demo_sk
   LEFT JOIN LATERAL (
     SELECT regexp_extract(web_site.web_zip, '^(\\d{3})') AS zip_prefix
   ) AS l ON true
   WHERE web_site.web_county LIKE '%County'
     AND web_site.web_name IS NOT NULL
     AND regexp_like(web_site.web_name, '^.*Site$')
   GROUP BY ws_bill_cdemo_sk, cd_gender, web_site.web_city, web_site.web_state, l.zip_prefix
),
union_all AS (
   SELECT * FROM store_part
   UNION
   SELECT * FROM web_part
)
SELECT
  demo_key,
  gender,
  total_net_paid,
  tx_cnt,
  descriptor,
  zip_prefix
FROM union_all
ORDER BY total_net_paid DESC
OFFSET 10
LIMIT 100
