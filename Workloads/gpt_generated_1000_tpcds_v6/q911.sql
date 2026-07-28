WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_ship_mode_sk,
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
      AND ws_ext_wholesale_cost < 5000
      AND ws_quantity >= 1
      AND ws_sold_date_sk BETWEEN 2450000 AND 2451500
      AND ws_ship_mode_sk IN (1, 6, 10, 17, 20)
    GROUP BY ws_item_sk, ws_ship_mode_sk, ws_bill_addr_sk
)
SELECT DISTINCT
    i.i_category,
    sm.sm_type,
    ca.ca_state,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.order_cnt
FROM ws_agg
JOIN item i ON ws_agg.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON ws_agg.ws_bill_addr_sk = ca.ca_address_sk
WHERE i.i_manufact = 'ationcallyought'
  AND sm.sm_contract = 'ldhM8IvpzHgdbBgDfI'
  AND ca.ca_country = 'United States'
  AND i.i_rec_start_date >= DATE '2000-01-01'
  AND i.i_rec_end_date <= DATE '2005-12-31'
ORDER BY ws_agg.total_sales DESC
LIMIT 100
