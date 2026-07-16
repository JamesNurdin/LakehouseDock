WITH monthly_site_sales AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_store_sk) AS distinct_store_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
      AND ws.web_state = 'CA'
    GROUP BY ws.web_site_id, ws.web_name, d.d_year, d.d_moy
)
SELECT
    web_site_id,
    web_name,
    year,
    month,
    total_net_profit,
    total_sales,
    avg_discount,
    total_quantity,
    distinct_store_cnt,
    RANK() OVER (PARTITION BY web_site_id ORDER BY total_net_profit DESC) AS profit_rank,
    LAG(total_net_profit) OVER (PARTITION BY web_site_id ORDER BY year, month) AS prev_month_profit,
    CASE
        WHEN LAG(total_net_profit) OVER (PARTITION BY web_site_id ORDER BY year, month) IS NULL THEN NULL
        ELSE (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY web_site_id ORDER BY year, month)) / LAG(total_net_profit) OVER (PARTITION BY web_site_id ORDER BY year, month) * 100
    END AS mom_profit_pct
FROM monthly_site_sales
ORDER BY web_site_id, year, month
