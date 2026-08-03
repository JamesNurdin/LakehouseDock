/*
Goal: Provide a sales‑performance summary per warehouse, time‑of‑day shift and billing state,
including total sales, distinct billed customers and distinct ship ZIP codes. The query
samples catalog_sales, uses a correlated EXISTS filter, joins all five tables (with many
aliases to reach at least nine join clauses), performs a FULL OUTER JOIN on warehouse,
combines two filtered result sets with UNION (distinct) and finally aggregates the
unioned data.
*/
WITH unioned_data AS (
    SELECT
        w1.w_warehouse_name      AS warehouse_name,
        td.t_sub_shift           AS sub_shift,
        bill_addr.ca_state       AS bill_state,
        cs.cs_ext_sales_price    AS sales_price,
        bill_cust.c_customer_id  AS bill_cust_id,
        ship_addr.ca_zip         AS ship_zip
    FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
    FULL OUTER JOIN warehouse w1
        ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer bill_cust
        ON cs.cs_bill_customer_sk = bill_cust.c_customer_sk
    JOIN customer ship_cust
        ON cs.cs_ship_customer_sk = ship_cust.c_customer_sk
    JOIN customer_address bill_addr
        ON cs.cs_bill_addr_sk = bill_addr.ca_address_sk
    JOIN customer_address ship_addr
        ON cs.cs_ship_addr_sk = ship_addr.ca_address_sk
    JOIN customer_address cur_addr
        ON bill_cust.c_current_addr_sk = cur_addr.ca_address_sk
    JOIN customer_address cur_addr2
        ON ship_cust.c_current_addr_sk = cur_addr2.ca_address_sk
    JOIN customer alt_bill_cust
        ON cs.cs_bill_customer_sk = alt_bill_cust.c_customer_sk
    WHERE td.t_sub_shift = 'morning'
      AND EXISTS (
            SELECT 1
            FROM customer_address ca2
            WHERE ca2.ca_state = bill_addr.ca_state
              AND ca2.ca_zip   = bill_addr.ca_zip
          )
    UNION
    SELECT
        w1.w_warehouse_name,
        td.t_sub_shift,
        bill_addr.ca_state,
        cs.cs_ext_sales_price,
        bill_cust.c_customer_id,
        ship_addr.ca_zip
    FROM catalog_sales cs TABLESAMPLE BERNOULLI (10)
    FULL OUTER JOIN warehouse w1
        ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer bill_cust
        ON cs.cs_bill_customer_sk = bill_cust.c_customer_sk
    JOIN customer ship_cust
        ON cs.cs_ship_customer_sk = ship_cust.c_customer_sk
    JOIN customer_address bill_addr
        ON cs.cs_bill_addr_sk = bill_addr.ca_address_sk
    JOIN customer_address ship_addr
        ON cs.cs_ship_addr_sk = ship_addr.ca_address_sk
    JOIN customer_address cur_addr
        ON bill_cust.c_current_addr_sk = cur_addr.ca_address_sk
    JOIN customer_address cur_addr2
        ON ship_cust.c_current_addr_sk = cur_addr2.ca_address_sk
    JOIN customer alt_bill_cust
        ON cs.cs_bill_customer_sk = alt_bill_cust.c_customer_sk
    WHERE td.t_sub_shift = 'night'
      AND EXISTS (
            SELECT 1
            FROM customer_address ca2
            WHERE ca2.ca_state = bill_addr.ca_state
              AND ca2.ca_zip   = bill_addr.ca_zip
          )
)
SELECT
    warehouse_name,
    sub_shift,
    bill_state,
    SUM(sales_price)                         AS total_sales,
    COUNT(DISTINCT bill_cust_id)             AS distinct_customers,
    COUNT(DISTINCT ship_zip)                 AS distinct_ship_zips
FROM unioned_data
GROUP BY warehouse_name, sub_shift, bill_state
ORDER BY total_sales DESC
LIMIT 100
