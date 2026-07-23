WITH sales_agg AS (
    SELECT
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_ext_sales_price,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count
    FROM tpcds.web_sales
    WHERE ws_ext_wholesale_cost BETWEEN 300 AND 2000
      AND ws_ext_ship_cost BETWEEN 100 AND 1000
      AND ws_quantity >= 2
      AND ws_ship_hdemo_sk IN (2525, 3114, 5032)
      AND ws_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY ws_web_page_sk
)
SELECT
    wp.wp_type,
    wp.wp_max_ad_count,
    CASE
        WHEN sales_agg.total_net_profit > 0 THEN 'profitable'
        ELSE 'loss'
    END AS profit_category,
    COUNT(DISTINCT wp.wp_web_page_id) AS page_count,
    SUM(sales_agg.total_ext_sales_price) AS sum_ext_sales_price,
    AVG(sales_agg.avg_discount) AS avg_discount_amount,
    MIN(sales_agg.total_quantity) AS min_total_quantity,
    MAX(sales_agg.total_quantity) AS max_total_quantity
FROM tpcds.web_page wp
JOIN sales_agg
    ON wp.wp_web_page_sk = sales_agg.ws_web_page_sk
WHERE wp.wp_rec_start_date >= DATE '1999-01-01'
  AND wp.wp_rec_start_date <= DATE '2001-12-31'
  AND wp.wp_max_ad_count >= 1
  AND wp.wp_type IN ('home', 'search', 'product')
  AND wp.wp_url LIKE 'http://%example.com%'
  AND wp.wp_autogen_flag = 'N'
GROUP BY
    wp.wp_type,
    wp.wp_max_ad_count,
    CASE
        WHEN sales_agg.total_net_profit > 0 THEN 'profitable'
        ELSE 'loss'
    END
ORDER BY sum_ext_sales_price DESC
LIMIT 100
