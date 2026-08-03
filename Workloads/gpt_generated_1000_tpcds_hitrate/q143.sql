WITH base AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_item_sk,
       ss.ss_addr_sk,
       ss.ss_ext_sales_price,
       ss.ss_ext_discount_amt,
       ss.ss_net_profit,
       d.d_year,
       d.d_qoy,
       d.d_month_seq,
       ca.ca_state,
       i.i_category,
       i.i_units,
       i.i_color
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND d.d_qoy = 2
     AND d.d_current_month = 'Y'
     AND i.i_units = 'Box'
     AND i.i_manufact_id = 350
     AND ss.ss_ext_discount_amt > 1000
),
agg AS (
   SELECT
       d_year,
       d_month_seq,
       ca_state,
       i_category,
       SUM(ss_ext_sales_price) AS total_sales,
       AVG(ss_ext_discount_amt) AS avg_discount,
       COUNT(*) AS txn_cnt,
       MAX(ss_net_profit) AS max_profit
   FROM base
   GROUP BY d_year, d_month_seq, ca_state, i_category
),
ranked AS (
   SELECT
       d_year,
       d_month_seq,
       ca_state,
       i_category,
       total_sales,
       avg_discount,
       txn_cnt,
       max_profit,
       ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
   FROM agg
),
attr_lookup AS (
   SELECT DISTINCT
       i_category,
       i_units,
       i_color
   FROM base
),
expanded AS (
   SELECT
       r.*,
       ARRAY[l.i_units, l.i_color] AS attrs
   FROM ranked r
   JOIN attr_lookup l ON l.i_category = r.i_category
)
SELECT
   d_year,
   d_month_seq,
   ca_state,
   i_category,
   total_sales,
   avg_discount,
   txn_cnt,
   max_profit,
   sales_rank,
   attr
FROM expanded
CROSS JOIN UNNEST(attrs) AS t(attr)
WHERE sales_rank <= 10
ORDER BY total_sales DESC
LIMIT 100
