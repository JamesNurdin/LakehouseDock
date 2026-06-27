WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_moy,
        wp.wp_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY ds.d_year, ds.d_moy, wp.wp_type
),
store_returns_agg AS (
    SELECT
        dsr.d_year,
        dsr.d_moy,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_count
    FROM store_returns sr
    JOIN date_dim dsr ON sr.sr_returned_date_sk = dsr.d_date_sk
    GROUP BY dsr.d_year, dsr.d_moy
),
web_returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_moy,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_count
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    GROUP BY dr.d_year, dr.d_moy
)
SELECT
    s.d_year,
    s.d_moy,
    s.wp_type,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(r.web_return_amount, 0) AS web_return_amount,
    COALESCE(r.web_net_loss, 0) AS web_net_loss,
    COALESCE(sr.store_return_amount, 0) AS store_return_amount,
    COALESCE(sr.store_net_loss, 0) AS store_net_loss,
    s.total_net_paid - COALESCE(r.web_return_amount, 0) - COALESCE(sr.store_return_amount, 0) AS net_paid_after_returns,
    s.total_net_profit - COALESCE(r.web_net_loss, 0) - COALESCE(sr.store_net_loss, 0) AS net_profit_after_returns,
    s.distinct_customers,
    s.total_quantity
FROM sales_agg s
LEFT JOIN web_returns_agg r
    ON s.d_year = r.d_year AND s.d_moy = r.d_moy
LEFT JOIN store_returns_agg sr
    ON s.d_year = sr.d_year AND s.d_moy = sr.d_moy
ORDER BY s.d_year, s.d_moy, s.wp_type
