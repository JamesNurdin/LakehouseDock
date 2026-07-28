WITH catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        (
            SELECT COALESCE(SUM(cr.cr_return_amount), 0)
            FROM catalog_returns cr
            JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
            WHERE dr.d_year = d.d_year
              AND dr.d_month_seq = d.d_month_seq
        ) AS total_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY GROUPING SETS ((d.d_year, d.d_month_seq), (d.d_year), ())
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        (
            SELECT COALESCE(SUM(cr.cr_return_amount), 0)
            FROM catalog_returns cr
            JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
            WHERE dr.d_year = d.d_year
              AND dr.d_month_seq = d.d_month_seq
        ) AS total_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY GROUPING SETS ((d.d_year, d.d_month_seq), (d.d_year), ())
)
SELECT
    ca.d_year,
    ca.d_month_seq,
    ca.channel,
    ca.total_sales,
    ca.order_cnt,
    ca.total_returns
FROM catalog_agg ca
WHERE NOT EXISTS (
    SELECT 1 FROM web_agg wa
    WHERE wa.channel = ca.channel
      AND wa.d_year = ca.d_year
      AND wa.d_month_seq = ca.d_month_seq
      AND wa.total_sales > ca.total_sales
)
UNION ALL
SELECT
    wa.d_year,
    wa.d_month_seq,
    wa.channel,
    wa.total_sales,
    wa.order_cnt,
    wa.total_returns
FROM web_agg wa
ORDER BY channel, d_year, d_month_seq, total_sales DESC
LIMIT 100
