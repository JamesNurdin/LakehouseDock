WITH store_sales_agg AS (
    SELECT
        s.s_store_id AS identifier,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
        CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag,
        CAST(NULL AS varchar) AS page_type,
        'Store' AS channel
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.store_returns sr
          JOIN tpcds.date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
          WHERE dr.d_year = 2001
            AND sr.sr_store_sk = s.s_store_sk
      )
    GROUP BY s.s_store_id, d.d_year, s.s_state
),
web_sales_agg AS (
    SELECT
        wp.wp_web_page_id AS identifier,
        d.d_year AS year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
        CAST(NULL AS varchar) AS region_flag,
        CASE WHEN wp.wp_type = 'home' THEN 'HomePage' ELSE 'OtherPage' END AS page_type,
        'Web' AS channel
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
    GROUP BY wp.wp_web_page_id, d.d_year, wp.wp_type
)
SELECT
    channel,
    identifier,
    year,
    total_sales,
    sales_category,
    region_flag,
    page_type
FROM store_sales_agg
UNION ALL
SELECT
    channel,
    identifier,
    year,
    total_sales,
    sales_category,
    region_flag,
    page_type
FROM web_sales_agg
ORDER BY year DESC, total_sales DESC
LIMIT 100
