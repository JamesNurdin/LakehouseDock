WITH sales_agg AS (
    SELECT
        'sales' AS record_type,
        d.d_year,
        sm.sm_type,
        cp.cp_catalog_page_id,
        cc.cc_state,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MIN(ws.ws_ship_date_sk) AS min_ship_date_sk,
        MAX(ws.ws_sold_date_sk) AS max_sold_date_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cp.cp_catalog_number BETWEEN 100 AND 200
      AND cc.cc_state = 'CA'
      AND ws.ws_net_paid_inc_ship_tax > 3000
    GROUP BY d.d_year, sm.sm_type, cp.cp_catalog_page_id, cc.cc_state
),
returns_agg AS (
    SELECT
        'return' AS record_type,
        d.d_year,
        sm.sm_type,
        cp.cp_catalog_page_id,
        cc.cc_state,
        SUM(wr.wr_net_loss) AS total_net_paid,
        AVG(wr.wr_return_amt) AS avg_discount,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        MIN(wr.wr_returned_date_sk) AS min_ship_date_sk,
        MAX(wr.wr_returned_date_sk) AS max_sold_date_sk
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cp.cp_catalog_number BETWEEN 100 AND 200
      AND cc.cc_state = 'CA'
      AND wr.wr_net_loss > 500
    GROUP BY d.d_year, sm.sm_type, cp.cp_catalog_page_id, cc.cc_state
)
SELECT *
FROM (
    SELECT DISTINCT * FROM sales_agg
    UNION ALL
    SELECT DISTINCT * FROM returns_agg
) combined
ORDER BY total_net_paid DESC
LIMIT 100
