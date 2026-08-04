WITH cr_dim AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_store_credit,
        cr.cr_return_ship_cost,
        cc.cc_call_center_id,
        cc.cc_market_manager,
        cc.cc_division_name,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        r.r_reason_desc
    FROM catalog_returns cr
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_ship_cost > 100
      AND cr.cr_net_loss < 2000
      AND cc.cc_market_manager = 'Kim Wilson'
      AND cc.cc_division_name = 'able'
      AND r.r_reason_desc IS NOT NULL
      AND cr.cr_store_credit > 0
),
ws_dim AS (
    SELECT
        ws.ws_quantity,
        ws.ws_list_price,
        ws.ws_wholesale_cost,
        ws.ws_net_profit,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        ws.ws_order_number
    FROM web_sales ws
    RIGHT OUTER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_list_price BETWEEN 50 AND 150
      AND ws.ws_wholesale_cost < 60
      AND ws.ws_quantity > 0
      AND sm.sm_type = 'AIR'
      AND w.w_city = 'Seattle'
      AND ws.ws_net_profit IS NOT NULL
),
combined AS (
    SELECT
        cr_dim.cc_call_center_id,
        cr_dim.cc_market_manager,
        cr_dim.cc_division_name,
        cr_dim.sm_ship_mode_id,
        cr_dim.w_warehouse_id,
        cr_dim.r_reason_desc,
        SUM(cr_dim.cr_return_amount) AS total_return_amount,
        SUM(cr_dim.cr_net_loss) AS total_net_loss,
        COUNT(*) AS cnt_returns
    FROM cr_dim
    GROUP BY
        cr_dim.cc_call_center_id,
        cr_dim.cc_market_manager,
        cr_dim.cc_division_name,
        cr_dim.sm_ship_mode_id,
        cr_dim.w_warehouse_id,
        cr_dim.r_reason_desc
),
combined_ws AS (
    SELECT
        ws_dim.sm_ship_mode_id,
        ws_dim.w_warehouse_id,
        SUM(ws_dim.ws_list_price * ws_dim.ws_quantity) AS total_sales_amount,
        SUM(ws_dim.ws_net_profit) AS total_net_profit,
        COUNT(*) AS cnt_sales
    FROM ws_dim
    GROUP BY
        ws_dim.sm_ship_mode_id,
        ws_dim.w_warehouse_id
),
full_combined AS (
    SELECT
        c.cc_call_center_id,
        c.cc_market_manager,
        c.cc_division_name,
        c.sm_ship_mode_id,
        c.w_warehouse_id,
        c.r_reason_desc,
        c.total_return_amount,
        c.total_net_loss,
        c.cnt_returns,
        ws.total_sales_amount,
        ws.total_net_profit,
        ws.cnt_sales
    FROM combined c
    FULL OUTER JOIN combined_ws ws
        ON c.sm_ship_mode_id = ws.sm_ship_mode_id
       AND c.w_warehouse_id = ws.w_warehouse_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY sm_ship_mode_id ORDER BY total_return_amount DESC) AS rn
    FROM full_combined
    WHERE total_return_amount IS NOT NULL
),
final AS (
    SELECT *
    FROM ranked
    WHERE rn <= 5
)
SELECT
    f.cc_call_center_id,
    f.cc_market_manager,
    f.cc_division_name,
    f.sm_ship_mode_id,
    f.w_warehouse_id,
    f.r_reason_desc,
    f.total_return_amount,
    f.total_net_loss,
    f.cnt_returns,
    f.total_sales_amount,
    f.total_net_profit,
    f.cnt_sales
FROM final f
WHERE f.total_net_profit > 1000
INTERSECT
SELECT
    f.cc_call_center_id,
    f.cc_market_manager,
    f.cc_division_name,
    f.sm_ship_mode_id,
    f.w_warehouse_id,
    f.r_reason_desc,
    f.total_return_amount,
    f.total_net_loss,
    f.cnt_returns,
    f.total_sales_amount,
    f.total_net_profit,
    f.cnt_sales
FROM final f
WHERE f.cnt_sales > 10
EXCEPT
SELECT
    f.cc_call_center_id,
    f.cc_market_manager,
    f.cc_division_name,
    f.sm_ship_mode_id,
    f.w_warehouse_id,
    f.r_reason_desc,
    f.total_return_amount,
    f.total_net_loss,
    f.cnt_returns,
    f.total_sales_amount,
    f.total_net_profit,
    f.cnt_sales
FROM final f
WHERE f.total_return_amount < 500
ORDER BY total_net_profit DESC
LIMIT 100
