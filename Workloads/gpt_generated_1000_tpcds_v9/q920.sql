WITH sales_demo_income AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d.d_quarter_name,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 1998
)
SELECT
    sdi.d_quarter_name,
    sdi.ib_lower_bound,
    sdi.ib_upper_bound,
    CASE
        WHEN sdi.ib_lower_bound >= 100000 THEN 'High Income'
        ELSE 'Low Income'
    END AS income_category,
    COUNT(DISTINCT sdi.ss_customer_sk) AS distinct_customers,
    SUM(sdi.ss_ext_sales_price) AS total_sales,
    SUM(sdi.ss_net_profit) AS total_profit,
    CASE
        WHEN SUM(sdi.ss_net_profit) > 10000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    COUNT(DISTINCT wp.wp_url) AS distinct_url_count,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    SUBSTRING(wp.wp_url, 1, 30) AS url_prefix,
    CONCAT(sdi.d_quarter_name, '_',
        CASE WHEN sdi.ib_lower_bound >= 100000 THEN 'HIGH' ELSE 'LOW' END) AS quarter_income_label
FROM sales_demo_income sdi
JOIN date_dim d2
    ON sdi.ss_sold_date_sk = d2.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d2.d_date_sk
WHERE REGEXP_LIKE(wp.wp_url, '^https?://[^/]+/electronics/.*\\.html$')
  AND wp.wp_type LIKE '%promo%'
GROUP BY
    sdi.d_quarter_name,
    sdi.ib_lower_bound,
    sdi.ib_upper_bound,
    CASE WHEN sdi.ib_lower_bound >= 100000 THEN 'High Income' ELSE 'Low Income' END,
    REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1),
    SUBSTRING(wp.wp_url, 1, 30),
    CONCAT(sdi.d_quarter_name, '_', CASE WHEN sdi.ib_lower_bound >= 100000 THEN 'HIGH' ELSE 'LOW' END)
HAVING SUM(sdi.ss_net_profit) > (
    SELECT AVG(inner_ss.ss_net_profit)
    FROM store_sales inner_ss
    JOIN date_dim inner_d ON inner_ss.ss_sold_date_sk = inner_d.d_date_sk
    WHERE inner_d.d_year = 1998
)
ORDER BY total_profit DESC
LIMIT 100
