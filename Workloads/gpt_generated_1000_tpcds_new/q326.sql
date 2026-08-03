WITH filtered_returns AS (
   SELECT cr_order_number,
          cr_return_amt_inc_tax,
          cr_return_quantity,
          cr_returned_date_sk,
          cr_item_sk,
          cr_refunded_customer_sk
   FROM catalog_returns
   WHERE cr_return_amt_inc_tax > 100
     AND cr_return_quantity > 1
     AND cr_returned_date_sk BETWEEN 2450000 AND 2450100
     AND cr_refunded_addr_sk IN (1177666, 4577336)
     AND cr_return_tax < 50
),
item_filter AS (
   SELECT i_item_sk,
          i_formulation,
          i_manufact,
          i_current_price,
          i_category
   FROM item
   WHERE i_formulation LIKE '%plum%'
     AND i_manufact = 'barprically'
     AND i_current_price BETWEEN 10 AND 100
     AND i_category = 'Electronics'
),
customer_filter AS (
   SELECT c_customer_sk,
          c_birth_month,
          c_salutation,
          c_preferred_cust_flag
   FROM customer
   WHERE c_birth_month = 12
     AND c_salutation = 'Mrs.'
     AND c_preferred_cust_flag = 'Y'
),
joined AS (
   SELECT fr.cr_order_number,
          fr.cr_return_amt_inc_tax,
          fr.cr_return_quantity,
          i.i_formulation,
          i.i_manufact,
          i.i_current_price,
          c.c_birth_month,
          c.c_salutation
   FROM filtered_returns fr
   JOIN item_filter i ON fr.cr_item_sk = i.i_item_sk
   JOIN customer_filter c ON fr.cr_refunded_customer_sk = c.c_customer_sk
),
agg AS (
   SELECT i_formulation,
          i_manufact,
          COUNT(*) AS cnt_returns,
          SUM(cr_return_amt_inc_tax) AS total_return_amount,
          AVG(cr_return_quantity) AS avg_quantity,
          MAX(cr_return_amt_inc_tax) AS max_return_amount,
          CASE WHEN SUM(cr_return_amt_inc_tax) > 5000 THEN 'HIGH' ELSE 'LOW' END AS high_low_flag
   FROM joined
   GROUP BY i_formulation, i_manufact
),
ranked AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY i_manufact ORDER BY total_return_amount DESC) AS rn
   FROM agg
),
order_numbers_all AS (
   SELECT cr_order_number FROM catalog_returns
),
order_numbers_recent AS (
   SELECT cr_order_number FROM catalog_returns WHERE cr_returned_date_sk >= 2450200
),
order_numbers_old AS (
   SELECT cr_order_number FROM catalog_returns WHERE cr_returned_date_sk < 2450000
),
order_numbers_excluded AS (
   SELECT cr_order_number FROM order_numbers_recent
   EXCEPT
   SELECT cr_order_number FROM order_numbers_old
),
order_numbers_common AS (
   SELECT cr_order_number FROM order_numbers_recent
   INTERSECT
   SELECT cr_order_number FROM order_numbers_all
)
SELECT r.i_formulation,
       r.i_manufact,
       r.cnt_returns,
       r.total_return_amount,
       r.avg_quantity,
       r.max_return_amount,
       r.high_low_flag,
       r.rn,
       (SELECT COUNT(*) FROM order_numbers_excluded) AS excluded_orders_cnt,
       (SELECT COUNT(*) FROM order_numbers_common) AS common_orders_cnt
FROM ranked r
ORDER BY r.total_return_amount DESC, r.rn
LIMIT 100
