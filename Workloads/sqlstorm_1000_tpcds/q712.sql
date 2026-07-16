WITH sales_union AS (
  SELECT ss_sold_date_sk AS sold_date_sk,
         ss_store_sk AS store_sk,
         NULL AS call_center_sk,
         NULL AS web_site_sk,
         ss_item_sk AS item_sk,
         ss_quantity AS quantity,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit
  FROM store_sales
  UNION ALL
  SELECT cs_sold_date_sk,
         NULL,
         cs_call_center_sk,
         NULL,
         cs_item_sk,
         cs_quantity,
         cs_net_paid,
         cs_net_profit
  FROM catalog_sales
  UNION ALL
  SELECT ws_sold_date_sk,
         NULL,
         NULL,
         ws_web_site_sk,
         ws_item_sk,
         ws_quantity,
         ws_net_paid,
         ws_net_profit
  FROM web_sales
),
agg AS (
  SELECT
    d.d_year,
    CASE
      WHEN s.store_sk IS NOT NULL THEN st.s_country
      WHEN s.call_center_sk IS NOT NULL THEN cc.cc_country
      WHEN s.web_site_sk IS NOT NULL THEN ws.web_country
      ELSE 'UNKNOWN'
    END AS country,
    i.i_category,
    SUM(s.net_paid) AS total_sales,
    SUM(s.net_profit) AS total_profit,
    SUM(s.quantity) AS total_quantity
  FROM sales_union s
  LEFT JOIN store st ON s.store_sk = st.s_store_sk
  LEFT JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
  LEFT JOIN web_site ws ON s.web_site_sk = ws.web_site_sk
  JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
  JOIN item i ON s.item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 1999
  GROUP BY d.d_year,
           CASE
             WHEN s.store_sk IS NOT NULL THEN st.s_country
             WHEN s.call_center_sk IS NOT NULL THEN cc.cc_country
             WHEN s.web_site_sk IS NOT NULL THEN ws.web_country
             ELSE 'UNKNOWN'
           END,
           i.i_category
  HAVING SUM(s.net_paid) > 100000
)
SELECT
  d_year,
  country,
  i_category,
  total_sales,
  total_profit,
  total_quantity,
  ROW_NUMBER() OVER (PARTITION BY d_year, country ORDER BY total_sales DESC) AS rank
FROM agg
ORDER BY d_year, country, rank
LIMIT 100
