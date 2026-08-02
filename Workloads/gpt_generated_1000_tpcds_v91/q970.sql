WITH sales_by_month AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        site.web_site_id AS web_site_id,
        sm.sm_carrier AS carrier,
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        SUM(ws.ws_ext_sales_price) AS month_sales,
        SUM(ws.ws_net_profit) AS month_profit
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE d_sold.d_year = 2000
        AND d_ship.d_month_seq BETWEEN 1 AND 12
        AND sm.sm_carrier = 'UPS'
        AND w.w_street_type = 'Ave'
        AND site.web_site_id LIKE 'AAAAAAA%'
        AND wp.wp_type = 'Category'
    GROUP BY
        w.w_warehouse_name,
        site.web_site_id,
        sm.sm_carrier,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    warehouse_name,
    web_site_id,
    carrier,
    year,
    month_seq,
    month_sales,
    month_profit,
    CASE
        WHEN month_profit > month_sales * 0.3 THEN 'HighMargin'
        ELSE 'LowMargin'
    END AS profit_category,
    SUM(month_sales) OVER (
        PARTITION BY warehouse_name
        ORDER BY year, month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_sales,
    LAG(month_sales) OVER (
        PARTITION BY warehouse_name
        ORDER BY year, month_seq
    ) AS previous_month_sales
FROM sales_by_month
WHERE month_sales > 0
ORDER BY warehouse_name, year, month_seq
LIMIT 100
