WITH
  sales_agg AS (
    SELECT
      ws.ws_bill_cdemo_sk AS cd_demo_sk,
      ws.ws_promo_sk AS promo_sk,
      d.d_year,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      AVG(ws.ws_ext_discount_amt) AS avg_discount,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '^Promo[0-9]+')
    GROUP BY ws.ws_bill_cdemo_sk, ws.ws_promo_sk, d.d_year
  ),
  site_agg AS (
    SELECT
      ws.ws_web_site_sk AS web_site_sk,
      ws.ws_promo_sk AS promo_sk,
      MIN(d.d_year) AS first_year,
      MAX(d.d_year) AS last_year,
      COUNT(DISTINCT ws.ws_order_number) AS orders_count,
      CONCAT('Site_', CAST(ws.ws_web_site_sk AS varchar)) AS site_label
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_site_sk, ws.ws_promo_sk
  )
SELECT
  COALESCE(sa.cd_demo_sk, -1) AS cd_demo_sk,
  cd.cd_gender AS gender,
  COALESCE(sa.sales_category, 'NO_SALES') AS sales_category,
  COALESCE(sa.total_sales, 0) AS total_sales,
  COALESCE(sa.avg_discount, 0) AS avg_discount,
  COALESCE(sb.site_label, 'UNKNOWN') AS site_label,
  COALESCE(sb.first_year, 0) AS first_year,
  COALESCE(sb.last_year, 0) AS last_year,
  COALESCE(sb.orders_count, 0) AS orders_count,
  (
    SELECT COUNT(*)
    FROM promotion p3
    WHERE p3.p_promo_sk = COALESCE(sa.promo_sk, sb.promo_sk)
      AND p3.p_discount_active = 'Y'
  ) AS active_promo_count,
  CONCAT('Year_', CAST(COALESCE(sa.d_year, sb.last_year) AS varchar)) AS year_label
FROM sales_agg sa
FULL OUTER JOIN site_agg sb ON sa.promo_sk = sb.promo_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = sa.cd_demo_sk
WHERE (cd.cd_gender IS NULL OR cd.cd_gender LIKE 'M%')
  AND (sb.site_label IS NULL OR regexp_like(sb.site_label, '^Site_[0-9]+$'))
UNION DISTINCT
SELECT
  -1 AS cd_demo_sk,
  NULL AS gender,
  'PROMO_ONLY' AS sales_category,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  NULL AS site_label,
  MIN(d.d_year) AS first_year,
  MAX(d.d_year) AS last_year,
  COUNT(DISTINCT ws.ws_order_number) AS orders_count,
  COUNT(*) FILTER (WHERE p.p_discount_active = 'Y') AS active_promo_count,
  CONCAT('Promo_', CAST(p.p_promo_sk AS varchar)) AS year_label
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE p.p_promo_name LIKE '%Discount%'
GROUP BY p.p_promo_sk
HAVING SUM(ws.ws_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
