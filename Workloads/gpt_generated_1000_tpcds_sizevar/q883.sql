WITH sales_base AS (
  SELECT *
  FROM web_sales
),
joined AS (
  SELECT
    sb.ws_order_number,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    w.w_warehouse_name,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    hd_bill.hd_buy_potential AS bill_buy_pot,
    hd_ship.hd_buy_potential AS ship_buy_pot,
    sb.ws_sales_price,
    sb.ws_net_profit,
    sb.ws_quantity
  FROM sales_base sb
  JOIN item i ON sb.ws_item_sk = i.i_item_sk                                   -- join 1
  JOIN household_demographics hd_bill ON sb.ws_bill_hdemo_sk = hd_bill.hd_demo_sk   -- join 2
  JOIN household_demographics hd_ship ON sb.ws_ship_hdemo_sk = hd_ship.hd_demo_sk   -- join 3 (reuse)
  JOIN customer_address ca_bill ON sb.ws_bill_addr_sk = ca_bill.ca_address_sk      -- join 4
  JOIN customer_address ca_ship ON sb.ws_ship_addr_sk = ca_ship.ca_address_sk      -- join 5 (reuse)
  JOIN ship_mode sm ON sb.ws_ship_mode_sk = sm.sm_ship_mode_sk                     -- join 6
  JOIN warehouse w ON sb.ws_warehouse_sk = w.w_warehouse_sk                        -- join 7
  LEFT JOIN web_returns wr ON sb.ws_order_number = wr.wr_order_number            -- join 8
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk                            -- join 9
  JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk                                      -- join 10 (second alias)
),
filtered AS (
  SELECT *
  FROM joined
  WHERE ws_order_number NOT IN (
    SELECT ws3.ws_order_number
    FROM web_sales ws3
    WHERE ws3.ws_quantity > 1000
  )
),
aggregated AS (
  SELECT
    i_category,
    i_brand,
    sm_type,
    SUM(ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    AVG(ws_sales_price) AS avg_price,
    CASE WHEN SUM(ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
  FROM filtered
  GROUP BY CUBE (i_category, i_brand, sm_type)
)
SELECT
  i_category,
  i_brand,
  sm_type,
  total_profit,
  order_cnt,
  avg_price,
  profit_flag,
  ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS row_num
FROM aggregated
WHERE total_profit IS NOT NULL
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
