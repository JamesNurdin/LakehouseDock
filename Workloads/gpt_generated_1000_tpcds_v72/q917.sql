WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        s.s_state AS state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, s.s_state
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        ws_site.web_state AS state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, ws_site.web_state
),
combined AS (
    SELECT 'store' AS channel, year, state, total_sales, distinct_customers
    FROM store_sales_agg
    UNION ALL
    SELECT 'web' AS channel, year, state, total_sales, distinct_customers
    FROM web_sales_agg
)
SELECT
    c.channel,
    c.year,
    c.state,
    c.total_sales,
    c.distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY c.year ORDER BY c.total_sales DESC) AS sales_rank,
    (SELECT AVG(total_sales) FROM combined WHERE year = c.year) AS avg_yearly_sales
FROM combined c
WHERE EXISTS (
    SELECT 1
    FROM store s2
    WHERE s2.s_state = c.state
      AND s2.s_number_employees > 50
)
ORDER BY c.year DESC, c.total_sales DESC
LIMIT 100
