WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_sold_date_sk,
    sm.sm_type,
    sm.sm_ship_mode_sk,
    hd.hd_vehicle_count
  FROM web_sales ws
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  WHERE sm.sm_type IN ('REGULAR', 'NEXT DAY', 'OVERNIGHT')
    AND ws.ws_net_profit > 0
    AND ws.ws_quantity >= 2
    AND ws.ws_sold_date_sk BETWEEN 24500 AND 25000
    AND NOT EXISTS (
      SELECT 1
      FROM web_sales ws2
      WHERE ws2.ws_order_number = ws.ws_order_number
        AND ws2.ws_net_profit < 0
    )
    AND ws.ws_ship_mode_sk NOT IN (
      SELECT sm_ship_mode_sk
      FROM ship_mode
      WHERE sm_code = 'SEA'
    )
),
agg_sales AS (
  SELECT
    sm_type,
    hd_vehicle_count,
    CASE
      WHEN ws_net_profit >= 1000 THEN 'HIGH'
      WHEN ws_net_profit >= 0 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_category,
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt
  FROM filtered_sales
  GROUP BY
    sm_type,
    hd_vehicle_count,
    CASE
      WHEN ws_net_profit >= 1000 THEN 'HIGH'
      WHEN ws_net_profit >= 0 THEN 'MEDIUM'
      ELSE 'LOW'
    END
)
SELECT
  sm_type,
  hd_vehicle_count,
  profit_category,
  total_sales,
  order_cnt,
  RANK() OVER (PARTITION BY sm_type ORDER BY total_sales DESC) AS sales_rank,
  SUM(total_sales) OVER (
    PARTITION BY profit_category
    ORDER BY total_sales
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_sales_by_category
FROM agg_sales
ORDER BY sm_type, sales_rank
