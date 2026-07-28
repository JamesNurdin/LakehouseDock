WITH filtered_sales AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        substring(wp.wp_url, 1, 10) AS url_prefix
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(wp.wp_url, '^https?://')
      AND wp.wp_type LIKE '%news%'
)
SELECT
    td.t_am_pm,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    fs.domain,
    COUNT(*) AS order_count,
    SUM(fs.ws_ext_sales_price) AS total_sales,
    AVG(fs.ws_net_profit) AS avg_profit,
    concat('Domain: ', fs.domain) AS label
FROM filtered_sales fs
JOIN time_dim td
    ON fs.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd
    ON fs.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE td.t_am_pm = 'PM'
  AND ib.ib_lower_bound >= 30000
  AND ib.ib_upper_bound <= 80000
GROUP BY td.t_am_pm, ib.ib_lower_bound, ib.ib_upper_bound, fs.domain
ORDER BY total_sales DESC
LIMIT 100
