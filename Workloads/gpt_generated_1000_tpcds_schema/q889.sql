WITH base_sales AS (
   SELECT
     ws.ws_item_sk,
     ws.ws_order_number,
     ws.ws_sold_date_sk,
     d.d_year,
     i.i_product_name,
     ws.ws_net_profit,
     ws.ws_coupon_amt,
     ws.ws_web_page_sk,
     ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
     CASE WHEN ws.ws_coupon_amt > 100 THEN 'HIGH' ELSE 'LOW' END AS coupon_level
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
),
sales_with_pages AS (
   SELECT
     bs.*, 
     lp.page_cnt
   FROM base_sales bs
   LEFT JOIN LATERAL (
      SELECT COUNT(*) AS page_cnt
      FROM web_page wp
      WHERE wp.wp_web_page_sk = bs.ws_web_page_sk
   ) lp ON true
),
qualified_sales AS (
   SELECT *
   FROM sales_with_pages swp
   WHERE EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_order_number = swp.ws_order_number
   )
)
SELECT
  ws_item_sk,
  i_product_name,
  coupon_level
FROM sales_with_pages
EXCEPT
SELECT
  ws_item_sk,
  i_product_name,
  coupon_level
FROM qualified_sales
LIMIT 100
