WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        ws.ws_sold_date_sk,
        d.d_year,
        ws.ws_promo_sk AS promo_sk,
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS order_cnt,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE d.d_year = 2001
      AND s.web_state = 'CA'
      AND ws.ws_ext_sales_price > 1000
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, d.d_year, ws.ws_promo_sk, p.p_promo_name, p.p_discount_active
)
SELECT
    sa.web_site_sk,
    s.web_name,
    sa.d_year,
    sa.promo_status,
    sa.total_sales,
    sa.total_discount,
    sa.order_cnt,
    ROUND(sa.total_sales / NULLIF(sa.order_cnt, 0), 2) AS avg_sales_per_order,
    ROW_NUMBER() OVER (PARTITION BY sa.web_site_sk ORDER BY sa.total_sales DESC) AS sales_rank,
    (SELECT COUNT(*) FROM web_sales ws2 WHERE ws2.ws_promo_sk = sa.promo_sk AND ws2.ws_ext_sales_price > 500) AS promo_highvalue_txn_cnt
FROM sales_agg sa
JOIN web_site s ON sa.web_site_sk = s.web_site_sk
WHERE sa.total_sales > (SELECT AVG(total_sales) FROM sales_agg)
ORDER BY sa.total_sales DESC
LIMIT 100
