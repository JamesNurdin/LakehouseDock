WITH joined_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_ship_date_sk,
       ws.ws_sales_price,
       ws.ws_ext_ship_cost,
       ws.ws_net_profit,
       sm.sm_carrier,
       ca_bill.ca_state AS bill_state,
       ca_ship.ca_state AS ship_state,
       wr.wr_return_tax,
       wr.wr_return_amt_inc_tax,
       CASE WHEN ws.ws_sales_price > 100 THEN 'High' ELSE 'Low' END AS price_category,
       ws.ws_bill_customer_sk
   FROM tpcds.web_sales ws
   JOIN tpcds.customer_address ca_bill
       ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN tpcds.customer_address ca_ship
       ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   JOIN tpcds.ship_mode sm
       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
      AND ws.ws_item_sk = wr.wr_item_sk
   JOIN tpcds.customer_address ca_refunded
       ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
   JOIN tpcds.customer_address ca_returning
       ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
   WHERE sm.sm_carrier IN ('FEDEX', 'BOXBUNDLES', 'DIAMOND', 'GERMA')
     AND ws.ws_ship_date_sk BETWEEN 2452288 AND 2452365
     AND wr.wr_return_tax > 20
     AND ca_bill.ca_state = 'CA'
),
aggregated AS (
   SELECT
       sm_carrier,
       price_category,
       SUM(ws_ext_ship_cost) AS total_ship_cost,
       SUM(wr_return_amt_inc_tax) AS total_return_amount,
       SUM(ws_net_profit) AS total_net_profit,
       COUNT(DISTINCT ws_bill_customer_sk) AS distinct_customers,
       AVG(ws_sales_price) AS avg_sales_price
   FROM joined_data
   GROUP BY sm_carrier, price_category
   HAVING SUM(wr_return_amt_inc_tax) > 500
)
SELECT
   sm_carrier,
   price_category,
   total_ship_cost,
   total_return_amount,
   total_net_profit,
   distinct_customers,
   avg_sales_price,
   RANK() OVER (ORDER BY total_return_amount DESC) AS carrier_return_rank,
   CASE WHEN total_net_profit > (SELECT AVG(total_net_profit) FROM aggregated)
        THEN 'Above Avg Profit' ELSE 'Below Avg Profit' END AS profit_vs_avg
FROM aggregated
WHERE total_ship_cost > 1000
  AND distinct_customers >= 5
  AND price_category = 'High'
ORDER BY total_return_amount DESC
LIMIT 100
