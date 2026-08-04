WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_net_profit IS NOT NULL
),
joined_data AS (
    SELECT
        ss.ws_web_site_sk,
        ss.ws_sold_date_sk,
        ss.ws_net_profit,
        ss.ws_ext_discount_amt,
        d.d_year,
        wp.wp_url,
        wp.wp_type,
        ws.web_name,
        ws.web_market_manager
    FROM sampled_sales ss
    JOIN date_dim d
        ON ss.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ss.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws
        ON ss.ws_web_site_sk = ws.web_site_sk
    WHERE regexp_like(wp.wp_url, '^https?://.*(sports|news).*')
      AND wp.wp_type LIKE '%content%'
),
ranked AS (
    SELECT
        jd.web_name,
        jd.d_year,
        regexp_extract(jd.wp_url, '://([^/]+)/', 1) AS domain,
        concat(jd.web_name, ':', regexp_extract(jd.wp_url, '://([^/]+)/', 1)) AS site_domain,
        CASE WHEN SUM(jd.ws_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category,
        COUNT(*) AS sales_count,
        SUM(jd.ws_net_profit) AS total_profit,
        (
            SELECT COUNT(*)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = jd.ws_web_site_sk
              AND ws2.ws_sold_date_sk = jd.ws_sold_date_sk
        ) AS daily_transactions,
        ROW_NUMBER() OVER (PARTITION BY jd.web_name ORDER BY SUM(jd.ws_net_profit) DESC) AS rnk
    FROM joined_data jd
    GROUP BY
        jd.web_name,
        jd.d_year,
        jd.wp_url,
        jd.ws_web_site_sk,
        jd.ws_sold_date_sk
)
SELECT
    web_name,
    d_year,
    domain,
    site_domain,
    profit_category,
    sales_count,
    total_profit,
    daily_transactions
FROM ranked
WHERE rnk <= 5
ORDER BY profit_category DESC, sales_count DESC
LIMIT 100
