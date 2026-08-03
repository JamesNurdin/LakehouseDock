WITH base_data AS (
   SELECT ws.ws_order_number,
          ws.ws_sold_date_sk,
          ws.ws_bill_addr_sk,
          ws.ws_bill_hdemo_sk,
          ws.ws_ext_sales_price,
          ws.ws_net_profit,
          ws.ws_list_price,
          ws.ws_quantity,
          d.d_date,
          d.d_year,
          ca.ca_city,
          ca.ca_state,
          ca.ca_zip,
          hd.hd_income_band_sk,
          hd.hd_buy_potential,
          cc.cc_name,
          cc.cc_state,
          cc.cc_employees
   FROM web_sales ws
   JOIN date_dim d           ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer_address ca  ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN call_center cc       ON cc.cc_open_date_sk = ws.ws_sold_date_sk
   WHERE ws.ws_ext_sales_price > 1200                         -- predicate 1
     AND ws.ws_quantity BETWEEN 2 AND 5                        -- predicate 2
     AND ws.ws_list_price BETWEEN 90 AND 250                    -- predicate 3
     AND d.d_year = 2000                                        -- predicate 4
     AND ca.ca_state = 'CA'                                     -- predicate 5
     AND ca.ca_gmt_offset = -8.00                               -- predicate 6
     AND hd.hd_buy_potential = '500-1000'                      -- predicate 7
     AND cc.cc_employees > 30                                   -- predicate 8
),
orders_to_exclude AS (
   SELECT ws_order_number
   FROM base_data
   WHERE ca_city = 'Los Angeles'
),
included_orders AS (
   SELECT ws_order_number
   FROM base_data
   EXCEPT
   SELECT ws_order_number
   FROM orders_to_exclude
),
filtered_data AS (
   SELECT b.*
   FROM base_data b
   JOIN included_orders i ON b.ws_order_number = i.ws_order_number
),
agg_a AS (
   SELECT cc_name,
          d_year,
          SUM(ws_ext_sales_price) AS total_sales,
          AVG(ws_net_profit)      AS avg_profit,
          COUNT(DISTINCT ws_order_number) AS order_cnt,
          MIN(ws_ext_sales_price) AS min_sales,
          MAX(ws_ext_sales_price) AS max_sales
   FROM filtered_data
   WHERE hd_income_band_sk = 5
   GROUP BY cc_name, d_year
),
agg_b AS (
   SELECT cc_name,
          d_year,
          SUM(ws_ext_sales_price) AS total_sales,
          AVG(ws_net_profit)      AS avg_profit,
          COUNT(DISTINCT ws_order_number) AS order_cnt,
          MIN(ws_ext_sales_price) AS min_sales,
          MAX(ws_ext_sales_price) AS max_sales
   FROM filtered_data
   WHERE hd_income_band_sk = 6
   GROUP BY cc_name, d_year
),
union_agg AS (
   SELECT * FROM agg_a
   UNION
   SELECT * FROM agg_b
)
SELECT *
FROM union_agg
ORDER BY total_sales DESC
OFFSET 10
LIMIT 100
