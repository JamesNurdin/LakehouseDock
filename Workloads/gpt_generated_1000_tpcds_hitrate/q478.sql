WITH
    sales_agg AS (
        SELECT
            ws.ws_ship_mode_sk,
            ws.ws_sold_time_sk,
            ws.ws_web_site_sk,
            SUM(ws.ws_net_profit)                AS total_net_profit,
            SUM(ws.ws_ext_sales_price)           AS total_sales,
            COUNT(DISTINCT ws.ws_order_number)   AS order_cnt
        FROM web_sales ws
        WHERE ws.ws_quantity >= 2
          AND ws.ws_net_paid > 0
          AND EXISTS (
                SELECT 1
                FROM web_returns wr
                WHERE wr.wr_item_sk = ws.ws_item_sk
                  AND wr.wr_order_number = ws.ws_order_number
                  AND wr.wr_return_quantity > 0
              )
        GROUP BY ws.ws_ship_mode_sk, ws.ws_sold_time_sk, ws.ws_web_site_sk
    ),
    returns_agg AS (
        SELECT
            ws.ws_ship_mode_sk,
            ws.ws_sold_time_sk,
            SUM(wr.wr_net_loss) AS total_return_loss,
            COUNT(*)            AS return_cnt
        FROM web_returns wr
        JOIN web_sales ws
          ON wr.wr_item_sk = ws.ws_item_sk
         AND wr.wr_order_number = ws.ws_order_number
        GROUP BY GROUPING SETS (
            (ws.ws_ship_mode_sk, ws.ws_sold_time_sk),
            (ws.ws_ship_mode_sk)
        )
    )
SELECT
    sm.sm_ship_mode_id,
    sm.sm_carrier,
    td.t_sub_shift,
    td.t_meal_time,
    sa.total_net_profit,
    sa.total_sales,
    sa.order_cnt,
    cr.cr_store_credit,
    cr.cr_return_ship_cost,
    CASE
        WHEN cr.cr_store_credit > 500 THEN 'HIGH_CREDIT'
        WHEN cr.cr_store_credit BETWEEN 100 AND 500 THEN 'MEDIUM_CREDIT'
        ELSE 'LOW_CREDIT'
    END AS credit_category,
    RANK() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY sa.total_net_profit DESC) AS profit_rank,
    COALESCE(ra.total_return_loss, 0)                               AS total_return_loss,
    SUM(cr.cr_net_loss) OVER (
        PARTITION BY sm.sm_ship_mode_id
        ORDER BY td.t_sub_shift
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_loss
FROM catalog_returns cr
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN sales_agg sa
  ON sm.sm_ship_mode_sk = sa.ws_ship_mode_sk
 AND td.t_time_sk = sa.ws_sold_time_sk
JOIN web_site ws
  ON sa.ws_web_site_sk = ws.web_site_sk
LEFT JOIN returns_agg ra
  ON ra.ws_ship_mode_sk = sm.sm_ship_mode_sk
 AND ra.ws_sold_time_sk = td.t_time_sk
WHERE td.t_sub_shift IN ('morning', 'afternoon')
  AND td.t_meal_time = 'breakfast'
  AND sm.sm_carrier = 'FEDEX'
  AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
  AND cr.cr_store_credit > 100
  AND ws.web_state = 'CA'
  AND cr.cr_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_carrier = 'FEDEX'
      )
ORDER BY profit_rank
LIMIT 100
