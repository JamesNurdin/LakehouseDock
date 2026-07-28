WITH joined AS (
    SELECT
        cc.cc_name,
        cc.cc_tax_percentage,
        w.w_warehouse_name,
        w.w_state AS warehouse_state,
        site.web_state AS site_state,
        ws.ws_net_paid,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_coupon_amt,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date,
        d_sold.d_weekend,
        wp.wp_type
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND d_sold.d_month_seq BETWEEN 1200 AND 1211
        AND d_sold.d_date = DATE '2001-06-15'
        AND d_sold.d_weekend = 'N'
        AND ws.ws_quantity > 5
        AND ws.ws_sales_price > 100
        AND w.w_state = 'CA'
        AND site.web_state = 'CA'
        AND cc.cc_tax_percentage > 0.05
        AND wp.wp_type = 'home'
),
aggregated AS (
    SELECT
        cc_name,
        w_warehouse_name,
        d_year,
        wp_type,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(*) AS order_cnt,
        MIN(ws_coupon_amt) AS min_coupon,
        MAX(ws_coupon_amt) AS max_coupon
    FROM joined
    GROUP BY cc_name, w_warehouse_name, d_year, wp_type
)
SELECT
    cc_name,
    w_warehouse_name,
    d_year,
    wp_type,
    total_net_paid,
    avg_sales_price,
    order_cnt,
    min_coupon,
    max_coupon,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank,
    SUM(total_net_paid) OVER (PARTITION BY d_year ORDER BY total_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_net
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
