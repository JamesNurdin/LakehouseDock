WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND ws.ws_sales_price > 20
      AND ws.ws_ship_mode_sk IN (9, 12, 17)
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND wsite.web_manager = 'Moses Hicks'
    GROUP BY ws.ws_web_site_sk, ws.ws_web_page_sk, ws.ws_warehouse_sk, ws.ws_promo_sk, d.d_year
),
returns_agg AS (
    SELECT
        cr.cr_warehouse_sk,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 5
    GROUP BY cr.cr_warehouse_sk, d.d_year
)
SELECT
    s.d_year,
    s.ws_web_site_sk,
    ws_name.web_name,
    SUM(s.total_sales) AS year_site_sales,
    SUM(s.total_profit) AS year_site_profit,
    SUM(r.total_return_amount) AS year_site_returns,
    (SUM(s.total_sales) - COALESCE(SUM(r.total_return_amount), 0)) / NULLIF(SUM(s.total_sales), 0) AS sales_return_ratio
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ws_warehouse_sk = r.cr_warehouse_sk
   AND s.d_year = r.d_year
JOIN web_site ws_name
    ON s.ws_web_site_sk = ws_name.web_site_sk
WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = s.ws_promo_sk
          AND p2.p_cost < 5000
      )
  AND s.total_sales > 10000
GROUP BY s.d_year, s.ws_web_site_sk, ws_name.web_name
HAVING SUM(s.total_sales) > 20000
ORDER BY s.d_year DESC, year_site_sales DESC
LIMIT 100
