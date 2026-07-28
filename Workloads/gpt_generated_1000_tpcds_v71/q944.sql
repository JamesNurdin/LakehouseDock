WITH ws AS (
   SELECT
      ws_order_number,
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_bill_customer_sk,
      ws_bill_addr_sk,
      ws_ship_mode_sk,
      ws_warehouse_sk,
      ws_web_page_sk,
      ws_quantity,
      ws_sales_price,
      ws_net_profit,
      ws_ext_sales_price
   FROM web_sales
   WHERE ws_quantity > 0
),
cr AS (
   SELECT
      cr_order_number,
      cr_returned_date_sk,
      cr_returned_time_sk,
      cr_refunded_customer_sk,
      cr_refunded_addr_sk,
      cr_ship_mode_sk,
      cr_warehouse_sk,
      cr_reason_sk,
      cr_return_amount,
      cr_net_loss
   FROM catalog_returns
   WHERE cr_return_amount > 0
)
SELECT
   ws.ws_order_number,
   d_sold.d_date                AS sold_date,
   t_sold.t_hour                AS sold_hour,
   d_return.d_date              AS return_date,
   t_return.t_hour              AS return_hour,
   c.c_first_name,
   c.c_last_name,
   ca.ca_city                   AS billing_city,
   sm.sm_type                   AS ship_mode,
   w.w_warehouse_name,
   wp.wp_url,
   r.r_reason_desc,
   cc.cc_name                   AS call_center_name,
   st.s_store_name,
   ws.ws_ext_sales_price,
   ws.ws_net_profit,
   ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d_sold.d_date DESC) AS rn_customer_sales,
   RANK()       OVER (ORDER BY ws.ws_net_profit DESC)               AS profit_rank
FROM ws
JOIN date_dim d_sold      ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold      ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN customer c           ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp          ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN store st        ON d_sold.d_date_sk = st.s_closed_date_sk
LEFT JOIN call_center cc  ON cc.cc_closed_date_sk = d_sold.d_date_sk
JOIN cr                   ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d_return    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return    ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
WHERE
   d_sold.d_year = 2001
   AND d_sold.d_month_seq BETWEEN 12 AND 14
   AND sm.sm_type IN ('AIR', 'RAIL')
   AND w.w_city = 'Seattle'
   AND c.c_preferred_cust_flag = 'Y'
   AND ca.ca_country = 'United States'
   AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
          AND cr2.cr_returned_date_sk = d_sold.d_date_sk
   )
ORDER BY profit_rank
LIMIT 100
