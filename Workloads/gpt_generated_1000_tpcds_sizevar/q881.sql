WITH base AS (
   SELECT
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_ext_discount_amt,
       ws.ws_net_profit,
       dim_sale.d_date AS sale_date,
       dim_sale_time.t_hour AS sale_hour,
       dim_ship.d_date AS ship_date,
       ca_bill.ca_state AS bill_state,
       ca_ship.ca_state AS ship_state,
       warehouse.w_warehouse_name,
       promotion.p_promo_name,
       promotion.p_discount_active,
       promotion.p_response_target,
       store.s_store_name,
       dim_return.d_date AS return_date,
       ca_refund.ca_state AS refund_state,
       ca_returning.ca_state AS returning_state,
       wr.wr_return_amt,
       wr.wr_return_quantity,
       lr.total_return_amt,
       CASE WHEN promotion.p_discount_active = 'Y' THEN ws.ws_ext_sales_price * 0.9 ELSE ws.ws_ext_sales_price END AS adjusted_price,
       CASE WHEN promotion.p_response_target > (SELECT AVG(p_response_target) FROM promotion) THEN 1 ELSE 0 END AS high_response_flag
   FROM web_sales ws
   JOIN date_dim dim_sale ON ws.ws_sold_date_sk = dim_sale.d_date_sk
   JOIN time_dim dim_sale_time ON ws.ws_sold_time_sk = dim_sale_time.t_time_sk
   JOIN date_dim dim_ship ON ws.ws_ship_date_sk = dim_ship.d_date_sk
   JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   JOIN warehouse ON ws.ws_warehouse_sk = warehouse.w_warehouse_sk
   JOIN promotion ON ws.ws_promo_sk = promotion.p_promo_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
   LEFT JOIN date_dim dim_return ON wr.wr_returned_date_sk = dim_return.d_date_sk
   LEFT JOIN time_dim dim_return_time ON wr.wr_returned_time_sk = dim_return_time.t_time_sk
   LEFT JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
   LEFT JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
   LEFT JOIN store ON store.s_closed_date_sk = dim_sale.d_date_sk
   CROSS JOIN LATERAL (
        SELECT sum(wr2.wr_return_amt) AS total_return_amt
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
   ) AS lr
),
windowed AS (
   SELECT
       *,
       LAG(adjusted_price) OVER (PARTITION BY ws_item_sk ORDER BY sale_date) AS prev_adj_price
   FROM base
),
agg1 AS (
   SELECT
       sale_date,
       ws_item_sk,
       COUNT(*) AS order_cnt,
       SUM(adjusted_price) AS sum_adj_price,
       SUM(total_return_amt) AS sum_return_amt,
       MAX(prev_adj_price) AS max_prev_adj_price,
       SUM(high_response_flag) AS high_resp_cnt
   FROM windowed
   WHERE adjusted_price > 1000
   GROUP BY sale_date, ws_item_sk
),
agg2 AS (
   SELECT
       sale_date,
       ws_item_sk,
       COUNT(*) AS order_cnt,
       SUM(adjusted_price) AS sum_adj_price,
       SUM(total_return_amt) AS sum_return_amt,
       MAX(prev_adj_price) AS max_prev_adj_price,
       SUM(high_response_flag) AS high_resp_cnt
   FROM windowed
   WHERE ship_state = 'CA'
   GROUP BY sale_date, ws_item_sk
),
agg3 AS (
   SELECT
       sale_date,
       ws_item_sk,
       COUNT(*) AS order_cnt,
       SUM(adjusted_price) AS sum_adj_price,
       SUM(total_return_amt) AS sum_return_amt,
       MAX(prev_adj_price) AS max_prev_adj_price,
       SUM(high_response_flag) AS high_resp_cnt
   FROM windowed
   WHERE return_date IS NULL
   GROUP BY sale_date, ws_item_sk
)
SELECT *
FROM (
   SELECT * FROM agg1
   UNION
   SELECT * FROM agg2
) 
EXCEPT
SELECT * FROM agg3
ORDER BY sale_date DESC, ws_item_sk
LIMIT 100
