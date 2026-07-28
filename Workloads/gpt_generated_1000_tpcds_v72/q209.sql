WITH sales_promos AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        REGEXP_EXTRACT(p.p_promo_id, '(A{5})(.*)') AS promo_suffix,
        SUBSTR(wp.wp_url, 1, 10) AS url_prefix,
        CONCAT(p.p_promo_id, '-', CAST(d.d_year AS varchar)) AS promo_year
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE REGEXP_LIKE(p.p_promo_id, '^AAAAAAA[AH].*$')
      AND c.c_first_name LIKE 'A%'
      AND wp.wp_url LIKE '%promo%'
    GROUP BY p.p_promo_sk, p.p_promo_id, d.d_year, d.d_month_seq, REGEXP_EXTRACT(p.p_promo_id, '(A{5})(.*)'), SUBSTR(wp.wp_url, 1, 10), CONCAT(p.p_promo_id, '-', CAST(d.d_year AS varchar))
)
SELECT
    sp.p_promo_id,
    sp.promo_year,
    sp.d_year,
    sp.d_month_seq,
    sp.total_sales,
    sp.sales_cnt,
    sp.promo_suffix,
    sp.url_prefix,
    (
        SELECT SUM(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_promo_sk = sp.p_promo_sk
    ) AS total_sales_all_time
FROM sales_promos sp
WHERE sp.total_sales > (
    SELECT AVG(ws3.ws_ext_sales_price)
    FROM web_sales ws3
    WHERE ws3.ws_promo_sk = sp.p_promo_sk
)
ORDER BY sp.total_sales DESC
LIMIT 100
