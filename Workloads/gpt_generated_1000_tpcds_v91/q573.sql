/*
Goal: Compare catalog and web sales performance by state and hour, focusing on orders that appear in catalog_sales but not in web_sales after applying multiple filters. The query aggregates sales and profit measures, computes the catalog sales share relative to overall catalog sales, and orders the results.
*/
WITH cs_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_time_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_ship_cdemo_sk,
        cs.cs_list_price
    FROM catalog_sales cs
    WHERE cs.cs_list_price > 50
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_ship_cdemo_sk IN (612200, 1913363)
      AND cs.cs_quantity BETWEEN 2 AND 10
),
ws_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ship_hdemo_sk,
        ws.ws_coupon_amt
    FROM web_sales ws
    WHERE ws.ws_ship_hdemo_sk IN (25, 702)
      AND ws.ws_coupon_amt > 200
      AND ws.ws_quantity BETWEEN 1 AND 5
),
cs_excl_ws AS (
    SELECT cs_order_number
    FROM cs_filtered
    EXCEPT
    SELECT ws_order_number
    FROM ws_filtered
)
SELECT
    ca_cs_bill.ca_state AS state,
    td.t_hour AS hour,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    (SUM(cs.cs_ext_sales_price) / NULLIF((SELECT SUM(cs2.cs_ext_sales_price) FROM catalog_sales cs2 WHERE cs2.cs_list_price > 100), 0)) AS catalog_sales_share
FROM cs_filtered cs
JOIN cs_excl_ws ce ON cs.cs_order_number = ce.cs_order_number
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca_cs_bill ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
JOIN customer_address ca_cs_ship ON cs.cs_ship_addr_sk = ca_cs_ship.ca_address_sk
JOIN ws_filtered ws ON ws.ws_sold_time_sk = td.t_time_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
WHERE ca_cs_bill.ca_state = 'CA'
  AND ca_cs_ship.ca_state <> 'NV'
  AND td.t_hour BETWEEN 9 AND 17
  AND td.t_meal_time = 'Lunch'
  AND ca_ws_bill.ca_state = 'TX'
  AND ca_ws_ship.ca_state NOT IN ('WA', 'OR')
GROUP BY ca_cs_bill.ca_state, td.t_hour
ORDER BY total_catalog_sales DESC, state
LIMIT 100
