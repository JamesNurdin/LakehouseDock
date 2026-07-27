WITH base AS (
  SELECT
    c.c_customer_id,
    d_sold.d_year,
    MIN(cc.cc_name) AS call_center_name,
    MIN(wsite.web_name) AS web_site_name,
    SUM(ss.ss_net_paid + ws.ws_net_paid) AS total_sales
  FROM store_sales ss
  JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN call_center cc
    ON cc.cc_open_date_sk = d_sold.d_date_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE
    d_sold.d_year BETWEEN 2000 AND 2002                -- filter 1: year range
    AND p.p_discount_active = 'Y'                     -- filter 2: active promotion
    AND cc.cc_country = 'United States'               -- filter 3: call‑center country
    AND cd.cd_gender = 'M'                             -- filter 4: male customers
  GROUP BY GROUPING SETS (
    (c.c_customer_id, d_sold.d_year),
    (c.c_customer_id),
    (d_sold.d_year)
  )
  HAVING SUM(ss.ss_net_paid + ws.ws_net_paid) > 10000
)
SELECT
  c_customer_id,
  d_year,
  total_sales,
  call_center_name,
  web_site_name,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM base
ORDER BY d_year, sales_rank
LIMIT 100
