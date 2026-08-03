WITH filtered_addresses AS (
       SELECT ca_address_sk,
              ca_state,
              ca_city,
              ca_county,
              ca_location_type
       FROM   customer_address
       WHERE  ca_county IN ('Washington County', 'Taos County')
         AND  ca_location_type = 'single family'
   ),
   high_value_sales AS (
       SELECT ws_bill_addr_sk,
              ws_ship_addr_sk,
              ws_net_paid_inc_ship,
              ws_ext_wholesale_cost,
              ws_quantity
       FROM   web_sales TABLESAMPLE BERNOULLI (10)
       WHERE  ws_net_paid_inc_ship > 2000
         AND  ws_ext_wholesale_cost > 500
   ),
   addr_bill AS (
       SELECT ws_bill_addr_sk AS addr_sk FROM high_value_sales
   ),
   addr_ship AS (
       SELECT ws_ship_addr_sk AS addr_sk FROM high_value_sales
   ),
   common_addrs AS (
       SELECT addr_sk FROM addr_bill
       INTERSECT
       SELECT addr_sk FROM addr_ship
   )
SELECT fa.ca_state,
       fa.ca_city,
       COUNT(*)                               AS order_cnt,
       SUM(hvs.ws_net_paid_inc_ship)          AS total_net_paid,
       AVG(hvs.ws_ext_wholesale_cost)          AS avg_wholesale_cost,
       MIN(hvs.ws_quantity)                   AS min_quantity,
       MAX(hvs.ws_quantity)                   AS max_quantity
FROM   high_value_sales hvs
JOIN   filtered_addresses fa
       ON hvs.ws_bill_addr_sk = fa.ca_address_sk
WHERE  hvs.ws_bill_addr_sk IN (SELECT addr_sk FROM common_addrs)
GROUP BY fa.ca_state,
         fa.ca_city
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
