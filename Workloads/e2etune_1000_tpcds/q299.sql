WITH returns_agg AS (
    SELECT
        i.i_category AS category,
        sm.sm_type AS ship_mode,
        td.t_hour AS hour,
        COUNT(DISTINCT cr.cr_returned_date_sk) AS return_days,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_warehouse_sk = 10
      AND cr.cr_refunded_customer_sk IN (6114601, 10425383)
      AND td.t_hour BETWEEN 10 AND 14
    GROUP BY i.i_category, sm.sm_type, td.t_hour
),
sales_agg AS (
    SELECT
        i.i_category AS category,
        sm.sm_type AS ship_mode,
        td.t_hour AS hour,
        SUM(ws.ws_quantity) AS total_sales_qty,
        SUM(ws.ws_net_paid) AS total_sales_net_paid,
        SUM(ws.ws_net_profit) AS total_sales_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales_ext_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_warehouse_sk = 10
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
      AND td.t_hour BETWEEN 10 AND 14
    GROUP BY i.i_category, sm.sm_type, td.t_hour
)
SELECT
    r.category,
    r.ship_mode,
    r.hour,
    r.total_return_amount,
    r.total_net_loss,
    r.total_return_qty,
    s.total_sales_qty,
    s.total_sales_net_paid,
    s.total_sales_net_profit,
    CASE WHEN s.total_sales_qty > 0 THEN r.total_return_qty / s.total_sales_qty ELSE NULL END AS return_rate,
    CASE WHEN s.total_sales_net_profit > 0 THEN r.total_net_loss / s.total_sales_net_profit ELSE NULL END AS loss_to_profit_ratio,
    RANK() OVER (PARTITION BY r.category ORDER BY CASE WHEN s.total_sales_qty > 0 THEN r.total_return_qty / s.total_sales_qty ELSE 0 END DESC) AS return_rate_rank
FROM returns_agg r
JOIN sales_agg s
  ON r.category = s.category
 AND r.ship_mode = s.ship_mode
 AND r.hour = s.hour
ORDER BY r.category, return_rate_rank
LIMIT 100
