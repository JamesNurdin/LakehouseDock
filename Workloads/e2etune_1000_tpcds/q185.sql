WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        d.d_year,
        d.d_quarter_name,
        wp.wp_type AS page_type,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        SUM(ws.ws_quantity) AS total_units_sold,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page ON wp.wp_creation_date_sk = d_page.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND d_page.d_year BETWEEN 2000 AND 2002
    GROUP BY sm.sm_ship_mode_id, d.d_year, d.d_quarter_name, wp.wp_type
),
returns_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        d.d_year,
        d.d_quarter_name,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_units_returned,
        COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY sm.sm_ship_mode_id, d.d_year, d.d_quarter_name
)
SELECT
    s.sm_ship_mode_id,
    s.d_year,
    s.d_quarter_name,
    s.page_type,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_units_sold,
    COALESCE(r.total_units_returned, 0) AS total_units_returned,
    s.order_cnt,
    COALESCE(r.return_order_cnt, 0) AS return_order_cnt,
    (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) AS net_contribution
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.sm_ship_mode_id = r.sm_ship_mode_id
    AND s.d_year = r.d_year
    AND s.d_quarter_name = r.d_quarter_name
WHERE s.total_sales_profit > 0
ORDER BY net_contribution DESC
LIMIT 100
