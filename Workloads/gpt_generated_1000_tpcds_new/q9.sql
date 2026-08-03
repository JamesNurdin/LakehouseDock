WITH store_sales_agg AS (
  SELECT
    s.s_store_id AS store_id,
    array_agg(DISTINCT p.p_promo_id) AS promo_ids,
    sum(ss.ss_net_paid) AS total_net_paid
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_store_id
),
store_sales_unnest AS (
  SELECT
    store_id,
    promo_id,
    total_net_paid
  FROM store_sales_agg
  CROSS JOIN UNNEST(promo_ids) AS t(promo_id)
),
web_sales_agg AS (
  SELECT
    ws.ws_web_site_sk AS site_id,
    array_agg(DISTINCT p.p_promo_id) AS promo_ids,
    sum(ws.ws_net_paid) AS total_net_paid
  FROM web_sales ws
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ws.ws_web_site_sk
),
web_sales_unnest AS (
  SELECT
    CAST(site_id AS varchar) AS store_id,
    promo_id,
    total_net_paid
  FROM web_sales_agg
  CROSS JOIN UNNEST(promo_ids) AS t(promo_id)
)
SELECT store_id, promo_id, total_net_paid
FROM store_sales_unnest
UNION
SELECT store_id, promo_id, total_net_paid
FROM web_sales_unnest
LIMIT 100
