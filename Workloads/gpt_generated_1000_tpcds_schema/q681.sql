WITH a AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_sales_price,
        td.t_hour,
        ib.ib_income_band_sk,
        sm.sm_ship_mode_id,
        w.w_warehouse_sk,
        we.web_site_id
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cs.cs_sales_price BETWEEN 20 AND 50
      AND ib.ib_upper_bound <= 120000
      AND sm.sm_code = 'AIR       '
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_order_number = cs.cs_order_number
            AND ws2.ws_quantity > 3
      )
),

b AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_sales_price,
        td.t_hour,
        ib.ib_income_band_sk,
        sm.sm_ship_mode_id,
        w.w_warehouse_sk,
        we.web_site_id
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE cs.cs_quantity >= 5
      AND ib.ib_lower_bound >= 80001
      AND sm.sm_code = 'SEA       '
      AND w.w_city = 'New York'
      AND EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_order_number = cs.cs_order_number
            AND ws2.ws_net_paid > 100
      )
),

union_set AS (
    SELECT * FROM a
    UNION
    SELECT * FROM b
),

exclude_set AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_sales_price,
        td.t_hour,
        ib.ib_income_band_sk,
        sm.sm_ship_mode_id,
        w.w_warehouse_sk,
        we.web_site_id
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE sm.sm_code = 'BIKE      '
)
SELECT
    us.t_hour,
    us.sm_ship_mode_id,
    COUNT(DISTINCT us.cs_order_number)               AS order_cnt,
    SUM(us.cs_net_paid)                               AS total_net_paid,
    AVG(us.cs_sales_price)                            AS avg_sales_price,
    MIN(us.cs_quantity)                               AS min_qty,
    MAX(us.cs_quantity)                               AS max_qty,
    (
        SELECT SUM(ws.ws_net_paid)
        FROM web_sales ws
        WHERE ws.ws_warehouse_sk = us.w_warehouse_sk
    )                                                 AS warehouse_net_paid_total
FROM (
    SELECT * FROM union_set
    EXCEPT
    SELECT * FROM exclude_set
) us
WHERE EXISTS (
    SELECT 1 FROM web_sales ws_check
    WHERE ws_check.ws_warehouse_sk = us.w_warehouse_sk
      AND ws_check.ws_net_paid > 0
)
GROUP BY us.t_hour, us.sm_ship_mode_id, us.w_warehouse_sk
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
