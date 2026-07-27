WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_promo_sk,
        ws.ws_sold_date_sk,
        wp.wp_url,
        cd.cd_gender,
        cd.cd_marital_status,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(wp.wp_url, '^https?://[^/]+/promo.*')
      AND wp.wp_url LIKE '%.com%'
)
SELECT
    fs.p_promo_name,
    fs.d_year,
    fs.d_month_seq,
    SUM(fs.ws_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count,
    CASE
        WHEN SUM(fs.ws_net_profit) > (
            SELECT AVG(sub.ws_net_profit)
            FROM web_sales sub
            JOIN date_dim subd ON sub.ws_sold_date_sk = subd.d_date_sk
            WHERE subd.d_year = fs.d_year
              AND subd.d_month_seq = fs.d_month_seq
        ) THEN 'ABOVE_AVG'
        ELSE 'BELOW_AVG'
    END AS profit_vs_avg,
    regexp_extract(fs.wp_url, 'https?://([^/]+)/', 1) AS domain,
    CONCAT(fs.p_promo_name, '_', regexp_extract(fs.wp_url, 'https?://([^/]+)/', 1)) AS promo_domain_key
FROM filtered_sales fs
GROUP BY
    fs.p_promo_name,
    fs.d_year,
    fs.d_month_seq,
    regexp_extract(fs.wp_url, 'https?://([^/]+)/', 1),
    CONCAT(fs.p_promo_name, '_', regexp_extract(fs.wp_url, 'https?://([^/]+)/', 1))
ORDER BY total_net_profit DESC
LIMIT 100
