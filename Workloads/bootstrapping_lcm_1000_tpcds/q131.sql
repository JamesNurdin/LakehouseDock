WITH sales_agg AS (
    SELECT
        sd.d_year AS sale_year,
        sd.d_month_seq AS sale_month_seq,
        shd.d_year AS ship_year,
        cd.d_year AS page_creation_year,
        ad.d_day_name AS page_access_day_name,
        d_closed.d_year AS store_closed_year,
        st.s_state AS store_state,
        wh.w_state AS warehouse_state,
        wp.wp_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        AVG(ws.ws_coupon_amt) AS avg_coupon_amt
    FROM web_sales ws
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN date_dim shd ON ws.ws_ship_date_sk = shd.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim cd ON wp.wp_creation_date_sk = cd.d_date_sk
    JOIN date_dim ad ON wp.wp_access_date_sk = ad.d_date_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN store st ON st.s_closed_date_sk = sd.d_date_sk
    JOIN date_dim d_closed ON st.s_closed_date_sk = d_closed.d_date_sk
    WHERE sd.d_year BETWEEN 2020 AND 2022
    GROUP BY
        sd.d_year,
        sd.d_month_seq,
        shd.d_year,
        cd.d_year,
        ad.d_day_name,
        d_closed.d_year,
        st.s_state,
        wh.w_state,
        wp.wp_type
)
SELECT
    sale_year,
    sale_month_seq,
    ship_year,
    page_creation_year,
    page_access_day_name,
    store_closed_year,
    store_state,
    warehouse_state,
    wp_type,
    total_net_paid,
    total_net_profit,
    order_count,
    avg_quantity,
    max_sales_price,
    min_sales_price,
    avg_coupon_amt,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
