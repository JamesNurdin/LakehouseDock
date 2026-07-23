WITH store_agg AS (
    SELECT
        d.d_date AS sale_date,
        s.s_store_name AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-01-31'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date, s.s_store_name
),
web_agg AS (
    SELECT
        d.d_date AS sale_date,
        w.web_name AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS transaction_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-01-31'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date, w.web_name
),
combined AS (
    SELECT sale_date, channel, total_sales, transaction_count FROM store_agg
    UNION ALL
    SELECT sale_date, channel, total_sales, transaction_count FROM web_agg
)
SELECT DISTINCT
    sale_date,
    channel,
    total_sales,
    transaction_count,
    (SELECT AVG(total_sales) FROM combined) AS avg_total_sales_overall
FROM combined
ORDER BY sale_date ASC, total_sales DESC
