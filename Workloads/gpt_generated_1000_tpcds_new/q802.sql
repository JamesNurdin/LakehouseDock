WITH filtered_sales AS (
    SELECT
        ws_warehouse_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_list_price,
        ws_ext_sales_price,
        ws_net_profit,
        ws_ship_hdemo_sk,
        ws_wholesale_cost,
        CASE WHEN ws_quantity > 5 THEN 'Bulk' ELSE 'Single' END AS qty_type
    FROM web_sales
    WHERE ws_list_price BETWEEN 50 AND 150
      AND ws_quantity BETWEEN 1 AND 20
      AND ws_wholesale_cost < 80
      AND ws_ship_hdemo_sk IN (4475, 1538, 1999)
      AND ws_net_profit > 0
      AND ws_ext_sales_price > 100
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    w.w_county,
    fs.qty_type,
    fs.ws_ext_sales_price,
    fs.ws_net_profit,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY fs.ws_ext_sales_price DESC) AS state_sales_rank,
    CASE
        WHEN fs.ws_net_profit > 500 THEN 'Very Profitable'
        WHEN fs.ws_net_profit > 200 THEN 'Profitable'
        ELSE 'Marginal'
    END AS profit_category
FROM filtered_sales fs
JOIN warehouse w
    ON fs.ws_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
          AND ws2.ws_net_profit > 1000
    )
  AND w.w_county = 'Bronx County'
  AND w.w_state = 'NY'
  AND w.w_city = 'Bronx'
ORDER BY w.w_state, state_sales_rank
LIMIT 100
