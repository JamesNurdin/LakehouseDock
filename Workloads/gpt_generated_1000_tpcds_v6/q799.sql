WITH filtered_dates AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
agg AS (
    SELECT
        s.s_store_name,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        GROUPING(s.s_store_name) AS grp_store,
        GROUPING(i.i_brand) AS grp_brand
    FROM filtered_dates d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        i.i_color = 'purple'
        AND wsite.web_country = 'United States'
        AND wp.wp_rec_start_date > DATE '1999-12-31'
    GROUP BY ROLLUP (s.s_store_name, i.i_brand)
)
SELECT
    a.s_store_name,
    a.i_brand,
    a.catalog_sales_total,
    a.web_sales_total,
    a.store_sales_total,
    a.catalog_orders,
    a.web_orders,
    a.store_orders,
    (SELECT AVG(i_current_price) FROM item WHERE i_color = 'purple') AS avg_purple_price,
    SUM(a.catalog_sales_total) OVER (PARTITION BY a.s_store_name) AS store_total_sales_win,
    a.grp_store,
    a.grp_brand
FROM agg a
ORDER BY
    a.s_store_name,
    a.i_brand
LIMIT 100
