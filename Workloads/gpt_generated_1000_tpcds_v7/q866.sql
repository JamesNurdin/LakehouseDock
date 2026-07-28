WITH sr AS (
   SELECT
       sr_returned_date_sk,
       sr_item_sk,
       sr_store_sk,
       sr_return_amt,
       sr_fee,
       sr_refunded_cash
   FROM store_returns
   WHERE sr_return_amt > 100
),
 date_filter AS (
   SELECT
       d_date_sk,
       d_year,
       d_month_seq,
       d_date
   FROM date_dim
   WHERE d_year = 2001
),
 item_filter AS (
   SELECT
       i_item_sk,
       i_brand,
       i_category,
       i_color
   FROM item
   WHERE i_brand = 'Brand#12'
),
 catalog_filter AS (
   SELECT
       cp_catalog_page_sk,
       cp_catalog_number,
       cp_department,
       cp_start_date_sk,
       cp_end_date_sk
   FROM catalog_page
   WHERE cp_catalog_number IN (7, 19)
),
 store_filter AS (
   SELECT
       s_store_sk,
       s_state,
       s_market_desc
   FROM store
   WHERE s_state = 'CA'
),
 web_filter AS (
   SELECT
       ws_item_sk,
       ws_sold_date_sk,
       ws_net_profit,
       ws_quantity
   FROM web_sales
   WHERE ws_quantity > 0
)
SELECT
   s.s_state,
   i.i_brand,
   cp.cp_department,
   d.d_year,
   COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold,
   SUM(sr.sr_return_amt) AS total_return_amount,
   SUM(ws.ws_net_profit) AS total_web_profit,
   AVG(ws.ws_quantity) AS avg_web_quantity,
   MIN(sr.sr_fee) AS min_return_fee,
   MAX(sr.sr_refunded_cash) AS max_refunded_cash
FROM sr
JOIN date_filter d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN item_filter i ON sr.sr_item_sk = i.i_item_sk
JOIN catalog_filter cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN store_filter s ON sr.sr_store_sk = s.s_store_sk
JOIN web_filter ws ON ws.ws_item_sk = i.i_item_sk
GROUP BY s.s_state, i.i_brand, cp.cp_department, d.d_year
ORDER BY total_web_profit DESC
LIMIT 100
