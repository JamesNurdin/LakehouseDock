WITH base_sales AS (
    SELECT
        d.d_date,
        d.d_year,
        t.t_hour,
        cd.cd_gender,
        hd.hd_income_band_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS store_sales_total,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS catalog_sales_total,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_count
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    FULL OUTER JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
       AND cs.cs_sold_time_sk = t.t_time_sk
       AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
       AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN date_dim d_open
        ON wsite.web_open_date_sk = d_open.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'F'
      AND hd.hd_income_band_sk IN (1, 2, 3)
      AND wsite.web_country = 'United States'
    GROUP BY d.d_date, d.d_year, t.t_hour, cd.cd_gender, hd.hd_income_band_sk
)
SELECT
    cd_gender,
    hd_income_band_sk,
    AVG(total_sales) AS avg_total_sales,
    SUM(store_sales_total) AS sum_store_sales,
    SUM(catalog_sales_total) AS sum_catalog_sales,
    SUM(web_sales_total) AS sum_web_sales,
    COUNT(*) AS num_days
FROM (
    SELECT
        d_year,
        cd_gender,
        hd_income_band_sk,
        (store_sales_total + catalog_sales_total + web_sales_total) AS total_sales,
        store_sales_total,
        catalog_sales_total,
        web_sales_total
    FROM base_sales
    WHERE (store_sales_total + catalog_sales_total + web_sales_total) > 10000
) agg
GROUP BY cd_gender, hd_income_band_sk
HAVING AVG(total_sales) > 5000
ORDER BY avg_total_sales DESC
LIMIT 100
