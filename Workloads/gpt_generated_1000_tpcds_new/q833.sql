WITH
  sales_filtered AS (
    SELECT ws.ws_order_number,
           ws.ws_sold_date_sk,
           ws.ws_ship_date_sk,
           ws.ws_bill_addr_sk,
           ws.ws_ship_addr_sk,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           ws.ws_coupon_amt
    FROM web_sales ws
    WHERE ws.ws_quantity BETWEEN 1 AND 10
      AND ws.ws_coupon_amt > 100
      AND ws.ws_ext_sales_price < (
        SELECT MAX(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_quantity = 1
      )
      AND ws.ws_bill_addr_sk IN (
        SELECT ca.ca_address_sk
        FROM customer_address ca
        WHERE ca.ca_state = 'CA'
      )
  ),
  returns_agg AS (
    SELECT wr.wr_order_number,
           SUM(wr.wr_return_amt) AS total_return_amt,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
    GROUP BY wr.wr_order_number
  ),
  intersect_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 5
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 2
  ),
  except_orders AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
  ),
  joined AS (
    SELECT sf.ws_order_number,
           sf.ws_quantity,
           sf.ws_ext_sales_price,
           sf.ws_net_profit,
           ra.total_return_amt,
           ra.return_cnt,
           d.d_year,
           d.d_month_seq,
           ca.ca_city,
           st.s_store_name,
           lc.max_cat_num
    FROM sales_filtered sf
    LEFT JOIN returns_agg ra ON sf.ws_order_number = ra.wr_order_number
    LEFT JOIN date_dim d ON sf.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer_address ca ON sf.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN store st ON st.s_closed_date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
      SELECT MAX(cp.cp_catalog_number) AS max_cat_num
      FROM catalog_page cp
      WHERE cp.cp_start_date_sk = d.d_date_sk
    ) lc ON TRUE
    WHERE lc.max_cat_num > 5
      AND d.d_year = 2001
      AND ca.ca_country = 'United States'
      AND st.s_state = 'CA'
      AND sf.ws_ext_sales_price > 0
  )
SELECT j.ws_order_number,
       j.ws_quantity,
       j.ws_ext_sales_price,
       j.ws_net_profit,
       j.total_return_amt,
       j.return_cnt,
       j.d_year,
       j.d_month_seq,
       j.ca_city,
       j.s_store_name,
       COUNT(*) OVER (PARTITION BY j.d_year) AS orders_per_year
FROM joined j
WHERE j.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
  AND j.ws_order_number NOT IN (SELECT ws_order_number FROM except_orders)
ORDER BY j.ws_net_profit DESC
LIMIT 100
