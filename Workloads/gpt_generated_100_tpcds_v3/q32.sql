WITH sales_agg AS (
    SELECT
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_quantity) AS avg_quantity,
        COUNT(*) AS sales_cnt,
        MIN(ws_sold_date_sk) AS min_sold_date_sk,
        MAX(ws_sold_date_sk) AS max_sold_date_sk
    FROM tpcds.web_sales
    WHERE ws_sold_time_sk BETWEEN 60000 AND 70000
      AND ws_ship_hdemo_sk NOT IN (3343, 5528)
      AND ws_web_site_sk = 7
    GROUP BY ws_web_page_sk
),
page_filter_union AS (
    SELECT wp_web_page_sk
    FROM tpcds.web_page
    WHERE wp_max_ad_count >= 3
    UNION
    SELECT wp_web_page_sk
    FROM tpcds.web_page
    WHERE wp_char_count > 3000
),
page_details AS (
    SELECT
        wp_web_page_sk,
        wp_url,
        wp_type,
        wp_max_ad_count,
        wp_char_count,
        wp_customer_sk,
        wp_rec_start_date,
        wp_rec_end_date,
        CASE
            WHEN wp_max_ad_count >= 3 THEN 'HighAds'
            ELSE 'LowAds'
        END AS ad_category
    FROM tpcds.web_page
    WHERE wp_max_ad_count IN (1, 2, 3)
      AND wp_char_count >= 2000
      AND wp_customer_sk = 6492078
      AND wp_rec_start_date >= DATE '2001-01-01'
      AND wp_rec_end_date <= DATE '2002-12-31'
      AND wp_type IN ('Content', 'Navigation')
)
SELECT
    pd.wp_web_page_sk,
    pd.wp_url,
    pd.wp_type,
    pd.ad_category,
    sa.total_sales,
    sa.total_profit,
    sa.avg_quantity,
    sa.sales_cnt,
    pd.wp_max_ad_count,
    pd.wp_char_count,
    CASE
        WHEN sa.total_sales > (SELECT AVG(total_sales) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_performance,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM tpcds.web_sales ws2
            WHERE ws2.ws_web_page_sk = pd.wp_web_page_sk
              AND ws2.ws_quantity > 5
        ) THEN 1
        ELSE 0
    END AS has_large_quantity_sales
FROM page_details pd
INNER JOIN sales_agg sa ON sa.ws_web_page_sk = pd.wp_web_page_sk
INNER JOIN page_filter_union pf ON pf.wp_web_page_sk = pd.wp_web_page_sk
WHERE pd.wp_max_ad_count BETWEEN 1 AND 3
  AND pd.wp_char_count BETWEEN 2000 AND 4000
  AND pd.wp_customer_sk = 6492078
  AND pd.wp_rec_start_date >= DATE '2001-01-01'
  AND pd.wp_rec_end_date <= DATE '2002-12-31'
  AND pd.wp_type IN ('Content', 'Navigation')
ORDER BY sa.total_sales DESC
LIMIT 100
