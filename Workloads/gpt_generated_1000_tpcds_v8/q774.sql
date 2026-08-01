WITH
  -- Bring customer information with a LEFT OUTER JOIN (allows NULLs for missing customers)
  base_left AS (
    SELECT
      ws.ws_order_number,
      ws.ws_warehouse_sk,
      ws.ws_bill_customer_sk,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_list_price,
      ws.ws_net_paid,
      ws.ws_net_profit,
      c.c_customer_sk,
      c.c_preferred_cust_flag,
      c.c_salutation,
      c.c_first_name,
      c.c_last_name
    FROM tpcds.web_sales ws
    LEFT JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ws.ws_list_price > 100
      AND ws.ws_sold_date_sk BETWEEN 2450700 AND 2450800
  ),

  -- Full outer join between sales and warehouses to keep unmatched rows on both sides
  full_join AS (
    SELECT
      ws.ws_order_number,
      ws.ws_warehouse_sk,
      w.w_warehouse_sk,
      w.w_warehouse_name,
      w.w_city,
      w.w_zip
    FROM tpcds.web_sales ws
    FULL OUTER JOIN tpcds.warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_zip = '33604'
  ),

  -- Main aggregation, includes a CASE expression and a window function
  main_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      w.w_warehouse_name,
      SUM(ls.ws_net_paid)                            AS total_net_paid,
      AVG(ls.ws_list_price)                          AS avg_list_price,
      COUNT(DISTINCT ls.ws_item_sk)                  AS distinct_items,
      MAX(ls.ws_net_profit)                          AS max_profit,
      CASE WHEN SUM(ls.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ls.ws_net_paid) DESC) AS rn
    FROM base_left ls
    JOIN full_join fj
      ON ls.ws_order_number = fj.ws_order_number
    JOIN tpcds.warehouse w
      ON fj.w_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer c
      ON ls.c_customer_sk = c.c_customer_sk
    WHERE EXISTS (
          SELECT 1
          FROM tpcds.web_sales ws2
          WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
            AND ws2.ws_ext_discount_amt > 10
        )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, w.w_warehouse_name
    HAVING SUM(ls.ws_net_paid) > 1000
  ),

  -- A set of groups we want to exclude (low‑value customers)
  exclude_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      w.w_warehouse_name,
      SUM(ls.ws_net_paid)                            AS total_net_paid,
      AVG(ls.ws_list_price)                          AS avg_list_price,
      COUNT(DISTINCT ls.ws_item_sk)                  AS distinct_items,
      MAX(ls.ws_net_profit)                          AS max_profit,
      CASE WHEN SUM(ls.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ls.ws_net_paid) DESC) AS rn
    FROM base_left ls
    JOIN full_join fj
      ON ls.ws_order_number = fj.ws_order_number
    JOIN tpcds.warehouse w
      ON fj.w_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer c
      ON ls.c_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, w.w_warehouse_name
    HAVING SUM(ls.ws_net_paid) <= 500
  )

SELECT *
FROM main_agg
EXCEPT
SELECT *
FROM exclude_agg
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
