WITH return_agg AS (
    SELECT
        d_ret.d_year AS year,
        d_ret.d_month_seq AS month,
        s.s_market_id,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        SUM(cr.cr_fee) AS total_return_fee,
        MAX(d_ret.d_date) AS max_return_date
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY d_ret.d_year, d_ret.d_month_seq, s.s_market_id
),
sales_agg AS (
    SELECT
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month,
        wp.wp_type,
        MIN(wp.wp_url) AS sample_url,
        COUNT(*) AS num_sales,
        SUM(ws.ws_net_paid) AS total_sales_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        AVG(ws.ws_quantity) AS avg_sales_qty,
        AVG(d_ship.d_month_seq - d_sold.d_month_seq) AS avg_ship_lag_months,
        MAX(d_ship.d_date) AS max_ship_date
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY d_sold.d_year, d_sold.d_month_seq, wp.wp_type
)
SELECT
    r.year,
    r.month,
    r.s_market_id,
    s.wp_type,
    r.num_returns,
    s.num_sales,
    r.total_return_amount,
    s.total_sales_net_paid,
    r.avg_return_qty,
    s.avg_sales_qty,
    r.total_return_fee,
    s.avg_ship_lag_months,
    CASE WHEN s.total_sales_net_paid > 0
        THEN r.total_return_amount / s.total_sales_net_paid
        ELSE NULL
    END AS return_to_sales_ratio,
    s.sample_url,
    r.max_return_date,
    s.max_ship_date
FROM return_agg r
JOIN sales_agg s
    ON r.year = s.year
   AND r.month = s.month
ORDER BY r.year, r.month, r.s_market_id, s.wp_type
LIMIT 100
