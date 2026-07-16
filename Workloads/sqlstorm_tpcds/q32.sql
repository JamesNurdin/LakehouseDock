WITH store_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    cd.cd_gender,
    sum(ss.ss_net_profit) AS store_net_profit,
    sum(ss.ss_ext_sales_price) AS store_sales,
    sum(ss.ss_quantity) AS store_quantity,
    approx_distinct(ss.ss_customer_sk) AS store_unique_customers
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender
),
catalog_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    cd.cd_gender,
    sum(cs.cs_net_profit) AS catalog_net_profit,
    sum(cs.cs_ext_sales_price) AS catalog_sales,
    sum(cs.cs_quantity) AS catalog_quantity,
    approx_distinct(cs.cs_bill_customer_sk) AS catalog_unique_customers
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender
),
web_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    cd.cd_gender,
    sum(ws.ws_net_profit) AS web_net_profit,
    sum(ws.ws_ext_sales_price) AS web_sales,
    sum(ws.ws_quantity) AS web_quantity,
    approx_distinct(ws.ws_bill_customer_sk) AS web_unique_customers
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  GROUP BY d.d_year, d.d_moy, i.i_category, cd.cd_gender
),
combined AS (
  SELECT
    coalesce(s.d_year, ca.d_year, w.d_year) AS year,
    coalesce(s.d_moy, ca.d_moy, w.d_moy) AS month,
    coalesce(s.i_category, ca.i_category, w.i_category) AS category,
    coalesce(s.cd_gender, ca.cd_gender, w.cd_gender) AS gender,
    s.store_net_profit,
    ca.catalog_net_profit,
    w.web_net_profit,
    s.store_sales,
    ca.catalog_sales,
    w.web_sales,
    s.store_quantity,
    ca.catalog_quantity,
    w.web_quantity,
    s.store_unique_customers,
    ca.catalog_unique_customers,
    w.web_unique_customers
  FROM store_agg s
  FULL OUTER JOIN catalog_agg ca
    ON s.d_year = ca.d_year
    AND s.d_moy = ca.d_moy
    AND s.i_category = ca.i_category
    AND s.cd_gender = ca.cd_gender
  FULL OUTER JOIN web_agg w
    ON coalesce(s.d_year, ca.d_year) = w.d_year
    AND coalesce(s.d_moy, ca.d_moy) = w.d_moy
    AND coalesce(s.i_category, ca.i_category) = w.i_category
    AND coalesce(s.cd_gender, ca.cd_gender) = w.cd_gender
)
SELECT
  year,
  month,
  category,
  gender,
  store_net_profit,
  catalog_net_profit,
  web_net_profit,
  (coalesce(store_net_profit, 0) + coalesce(catalog_net_profit, 0) + coalesce(web_net_profit, 0)) AS total_net_profit,
  (coalesce(store_sales, 0) + coalesce(catalog_sales, 0) + coalesce(web_sales, 0)) AS total_sales,
  (coalesce(store_quantity, 0) + coalesce(catalog_quantity, 0) + coalesce(web_quantity, 0)) AS total_quantity,
  (coalesce(store_unique_customers, 0) + coalesce(catalog_unique_customers, 0) + coalesce(web_unique_customers, 0)) AS total_unique_customers,
  row_number() OVER (PARTITION BY year, month ORDER BY (coalesce(store_net_profit, 0) + coalesce(catalog_net_profit, 0) + coalesce(web_net_profit, 0)) DESC) AS profit_rank
FROM combined
WHERE year >= 2000
ORDER BY year, month, total_net_profit DESC
LIMIT 100
