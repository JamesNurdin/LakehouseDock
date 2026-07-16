WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers,
        SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_profit) AS catalog_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customers,
        SUM(cs.cs_quantity) AS catalog_qty
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
),
web_sales_agg AS (
    SELECT
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
)
SELECT
    s.d_year,
    s.cd_gender,
    s.cd_marital_status,
    s.store_profit,
    c.catalog_profit,
    w.web_profit,
    (s.store_profit + c.catalog_profit + w.web_profit) AS total_profit,
    CASE WHEN (s.store_profit + c.catalog_profit + w.web_profit) = 0 THEN 0
         ELSE s.store_profit / (s.store_profit + c.catalog_profit + w.web_profit) END AS store_profit_pct,
    CASE WHEN (s.store_profit + c.catalog_profit + w.web_profit) = 0 THEN 0
         ELSE c.catalog_profit / (s.store_profit + c.catalog_profit + w.web_profit) END AS catalog_profit_pct,
    CASE WHEN (s.store_profit + c.catalog_profit + w.web_profit) = 0 THEN 0
         ELSE w.web_profit / (s.store_profit + c.catalog_profit + w.web_profit) END AS web_profit_pct,
    s.store_customers + c.catalog_customers + w.web_customers AS total_customers,
    s.store_qty + c.catalog_qty + w.web_qty AS total_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY (s.store_profit + c.catalog_profit + w.web_profit) DESC) AS profit_rank
FROM store_sales_agg s
JOIN catalog_sales_agg c
    ON s.d_year = c.d_year
   AND s.cd_gender = c.cd_gender
   AND s.cd_marital_status = c.cd_marital_status
JOIN web_sales_agg w
    ON s.d_year = w.d_year
   AND s.cd_gender = w.cd_gender
   AND s.cd_marital_status = w.cd_marital_status
WHERE s.d_year >= 1998
ORDER BY s.d_year, profit_rank
LIMIT 100
