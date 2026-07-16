WITH cr_agg AS (
    SELECT
        d_ret.d_year AS year,
        d_ret.d_month_seq AS month_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    GROUP BY d_ret.d_year, d_ret.d_month_seq
),
ws_agg AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_sold,
        SUM(CASE WHEN wp.wp_type = 'product' THEN ws.ws_net_profit ELSE 0 END) AS product_page_profit,
        SUM(CASE WHEN wp.wp_type = 'category' THEN ws.ws_net_profit ELSE 0 END) AS category_page_profit
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY d_sold.d_year, d_sold.d_month_seq
),
store_agg AS (
    SELECT
        d_store.d_year AS year,
        d_store.d_month_seq AS month_seq,
        COUNT(*) AS stores_closed_cnt,
        SUM(s.s_floor_space) AS total_floor_space
    FROM store s
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    GROUP BY d_store.d_year, d_store.d_month_seq
),
wp_agg AS (
    SELECT
        d_create.d_year AS year,
        d_create.d_month_seq AS month_seq,
        COUNT(*) AS pages_created,
        SUM(wp.wp_image_count) AS total_image_count,
        AVG(date_diff('day', d_create.d_date, d_access.d_date)) AS avg_days_to_access,
        AVG(wp.wp_char_count) AS avg_char_count
    FROM web_page wp
    JOIN date_dim d_create
        ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY d_create.d_year, d_create.d_month_seq
)
SELECT
    COALESCE(cr.year, ws.year, st.year, wp.year) AS year,
    COALESCE(cr.month_seq, ws.month_seq, st.month_seq, wp.month_seq) AS month_seq,
    cr.total_return_amount,
    cr.total_return_quantity,
    cr.total_net_loss,
    cr.return_cnt,
    ws.total_net_profit,
    ws.total_quantity,
    ws.total_discount,
    ws.avg_days_to_ship,
    ws.order_cnt,
    ws.distinct_pages_sold,
    ws.product_page_profit,
    ws.category_page_profit,
    st.stores_closed_cnt,
    st.total_floor_space,
    wp.pages_created,
    wp.total_image_count,
    wp.avg_days_to_access,
    wp.avg_char_count
FROM cr_agg cr
FULL OUTER JOIN ws_agg ws
    ON cr.year = ws.year AND cr.month_seq = ws.month_seq
FULL OUTER JOIN store_agg st
    ON COALESCE(cr.year, ws.year) = st.year
   AND COALESCE(cr.month_seq, ws.month_seq) = st.month_seq
FULL OUTER JOIN wp_agg wp
    ON COALESCE(cr.year, ws.year, st.year) = wp.year
   AND COALESCE(cr.month_seq, ws.month_seq, st.month_seq) = wp.month_seq
ORDER BY year, month_seq
