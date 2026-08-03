WITH store_customer AS (
  SELECT
    ss.ss_customer_sk,
    cd.cd_gender,
    array_agg(DISTINCT ss.ss_store_sk) AS store_ids
  FROM store_sales ss
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2451400 AND 2451500
  GROUP BY ss.ss_customer_sk, cd.cd_gender
),
store_expanded AS (
  SELECT
    sc.ss_customer_sk AS customer_sk,
    sc.cd_gender,
    store_id
  FROM store_customer sc
  CROSS JOIN UNNEST(sc.store_ids) AS t(store_id)
),
web_customer AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    cd.cd_gender,
    array_agg(DISTINCT ws.ws_web_site_sk) AS site_ids
  FROM web_sales ws
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2451400 AND 2451500
  GROUP BY ws.ws_bill_customer_sk, cd.cd_gender
),
web_expanded AS (
  SELECT
    wc.customer_sk,
    wc.cd_gender,
    site_id
  FROM web_customer wc
  CROSS JOIN UNNEST(wc.site_ids) AS t(site_id)
)
SELECT DISTINCT se.customer_sk,
       se.cd_gender,
       se.store_id AS channel_id
FROM store_expanded se
INTERSECT
SELECT DISTINCT we.customer_sk,
       we.cd_gender,
       we.site_id AS channel_id
FROM web_expanded we
ORDER BY customer_sk
OFFSET 10
LIMIT 100
