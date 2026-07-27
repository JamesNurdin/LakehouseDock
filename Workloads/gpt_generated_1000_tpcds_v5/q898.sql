WITH sales_agg AS (
  SELECT
    ws.ws_order_number,
    ws.ws_web_site_sk,
    ws.ws_warehouse_sk,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
  FROM web_sales ws
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_vehicle_count > 1
    AND ws.ws_quantity >= 2
    AND ws.ws_net_profit > 0
    AND ws.ws_ext_sales_price > 100
  GROUP BY ws.ws_order_number, ws.ws_web_site_sk, ws.ws_warehouse_sk
),
joined_data AS (
  SELECT
    sa.ws_order_number,
    sa.total_sales,
    sa.total_profit,
    sa.avg_quantity,
    sa.distinct_items,
    wr.wr_return_amt,
    wr.wr_return_ship_cost,
    COALESCE(w.w_warehouse_name, 'UNKNOWN') AS warehouse_name,
    s.web_site_id,
    s.web_city,
    s.web_street_name,
    s.web_market_manager
  FROM sales_agg sa
  JOIN web_returns wr
    ON wr.wr_order_number = sa.ws_order_number
  LEFT JOIN warehouse w
    ON w.w_warehouse_sk = sa.ws_warehouse_sk
  JOIN web_site s
    ON s.web_site_sk = sa.ws_web_site_sk
  WHERE wr.wr_return_ship_cost > 200
    AND s.web_street_name IN ('Broadway South', 'Ridge Wilson')
    AND s.web_market_manager = 'James Harris'
    AND w.w_county = 'Bronx County'
    AND s.web_city = 'New York'
)
SELECT
  web_site_id,
  warehouse_name,
  SUM(total_sales) AS site_sales,
  SUM(total_profit) AS site_profit,
  SUM(wr_return_amt) AS total_return_amount,
  COUNT(DISTINCT ws_order_number) AS distinct_orders,
  AVG(avg_quantity) AS avg_quantity_per_order,
  ROW_NUMBER() OVER (ORDER BY SUM(total_sales) DESC) AS sales_rank
FROM joined_data
GROUP BY web_site_id, warehouse_name
HAVING SUM(total_sales) > 5000
ORDER BY site_sales DESC
LIMIT 100
