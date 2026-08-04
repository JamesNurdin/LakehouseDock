WITH date_sample AS (
        SELECT d_date_sk,
               d_date,
               d_year,
               d_quarter_seq,
               d_fy_week_seq
        FROM date_dim
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_cust AS (
        SELECT ss.ss_sold_date_sk,
               ss.ss_cdemo_sk,
               ss.ss_ext_sales_price,
               ss.ss_net_profit,
               ss.ss_quantity,
               cd.cd_gender,
               cd.cd_marital_status,
               cd.cd_purchase_estimate
        FROM store_sales ss
        JOIN customer_demographics cd
          ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE ss.ss_ext_sales_price > 1000
          AND cd.cd_purchase_estimate BETWEEN 5000 AND 10000
          AND cd.cd_marital_status = 'M'
    ),
    wp_ws AS (
        SELECT wp.wp_web_page_sk,
               wp.wp_url,
               wp.wp_type,
               ws.web_site_sk,
               ws.web_name,
               ws.web_city,
               ds.d_year AS web_year,
               ds.d_fy_week_seq AS web_fy_week_seq
        FROM web_page wp
        JOIN date_sample ds
          ON wp.wp_creation_date_sk = ds.d_date_sk
        FULL OUTER JOIN web_site ws
          ON ws.web_open_date_sk = ds.d_date_sk
        WHERE wp.wp_type = 'Content'
          AND (ws.web_state = 'CA' OR ws.web_state IS NULL)
          AND ds.d_fy_week_seq = 9
    )
SELECT
    sc.cd_gender,
    sc.cd_marital_status,
    sc.cd_purchase_estimate,
    d.d_year,
    d.d_quarter_seq,
    sc.ss_ext_sales_price,
    sc.ss_net_profit,
    CASE
        WHEN sc.ss_net_profit >= 5000 THEN 'HIGH'
        WHEN sc.ss_net_profit BETWEEN 1000 AND 4999.99 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    wp_ws.wp_url,
    wp_ws.web_name,
    wp_ws.web_city,
    ROW_NUMBER() OVER (PARTITION BY sc.cd_gender ORDER BY sc.ss_ext_sales_price DESC) AS gender_sales_rank,
    (
        SELECT AVG(inner_sc.ss_net_profit)
        FROM sales_cust inner_sc
        WHERE inner_sc.cd_gender = sc.cd_gender
    ) AS avg_gender_profit
FROM sales_cust sc
JOIN date_sample d
  ON sc.ss_sold_date_sk = d.d_date_sk
FULL OUTER JOIN wp_ws
  ON d.d_year = wp_ws.web_year
WHERE d.d_quarter_seq = 3
  AND sc.ss_quantity > 1
  AND sc.ss_ext_sales_price < 20000
ORDER BY sc.ss_ext_sales_price DESC
LIMIT 100
