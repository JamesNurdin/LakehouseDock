WITH
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_moy AS varchar), 2, '0')) AS year_month,
        ss.ss_net_profit AS net_profit_store,
        CAST(0 AS decimal(15,2)) AS net_profit_catalog,
        CAST(0 AS decimal(15,2)) AS net_profit_web
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_moy AS varchar), 2, '0')) AS year_month,
        CAST(0 AS decimal(15,2)) AS net_profit_store,
        cs.cs_net_profit AS net_profit_catalog,
        CAST(0 AS decimal(15,2)) AS net_profit_web
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        CONCAT(CAST(d.d_year AS varchar), '-', LPAD(CAST(d.d_moy AS varchar), 2, '0')) AS year_month,
        CAST(0 AS decimal(15,2)) AS net_profit_store,
        CAST(0 AS decimal(15,2)) AS net_profit_catalog,
        ws.ws_net_profit AS net_profit_web
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
all_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
aggregated_sales AS (
    SELECT
        customer_sk,
        customer_id,
        year,
        month_seq,
        year_month,
        SUM(net_profit_store) AS net_profit_store,
        SUM(net_profit_catalog) AS net_profit_catalog,
        SUM(net_profit_web) AS net_profit_web,
        SUM(net_profit_store) + SUM(net_profit_catalog) + SUM(net_profit_web) AS net_profit_total
    FROM all_sales
    GROUP BY
        customer_sk,
        customer_id,
        year,
        month_seq,
        year_month
),
customer_demog AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_with_demo AS (
    SELECT
        a.*,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        CONCAT(a.customer_id, ':', a.year_month) AS cust_month_key
    FROM aggregated_sales a
    LEFT JOIN customer_demog d ON a.customer_sk = d.c_customer_sk
),
ranked_sales AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.year_month ORDER BY s.net_profit_total DESC) AS rank_month,
        AVG(s.net_profit_total) OVER (PARTITION BY s.customer_sk ORDER BY s.month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m
    FROM sales_with_demo s
),
final AS (
    SELECT
        r.customer_id,
        r.year_month,
        r.net_profit_total,
        r.net_profit_store,
        r.net_profit_catalog,
        r.net_profit_web,
        r.rank_month,
        r.moving_avg_3m,
        r.cd_gender,
        r.cd_marital_status,
        r.cust_month_key,
        CASE
            WHEN r.cd_gender IS NULL THEN 'UNKNOWN'
            ELSE r.cd_gender
        END AS gender,
        CASE
            WHEN r.cd_marital_status IS NULL THEN 'UNKNOWN'
            ELSE r.cd_marital_status
        END AS marital_status,
        (SELECT AVG(r2.net_profit_total)
         FROM ranked_sales r2
         WHERE r2.cd_gender = r.cd_gender
           AND r2.year_month = r.year_month) AS avg_same_gender_month_profit,
        CASE
            WHEN r.net_profit_total > (SELECT AVG(r2.net_profit_total)
                                      FROM ranked_sales r2
                                      WHERE r2.cd_gender = r.cd_gender
                                        AND r2.year_month = r.year_month) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_vs_gender_avg,
        CASE
            WHEN r.net_profit_total IS NULL OR r.net_profit_total = 0 THEN 1
            ELSE 0
        END AS zero_or_null_flag
    FROM ranked_sales r
    WHERE r.rank_month <= 10
)
SELECT *
FROM final
ORDER BY year_month, rank_month
