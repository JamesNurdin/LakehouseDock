WITH
  sales_2000 AS (
    SELECT s.s_store_id,
           s.s_state,
           SUM(ss.ss_ext_sales_price) AS amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_id, s.s_state
  ),
  returns_2000 AS (
    SELECT s.s_store_id,
           s.s_state,
           -SUM(sr.sr_return_amt) AS amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_id, s.s_state
  ),
  union_amounts AS (
    SELECT s_store_id, s_state, amount FROM sales_2000
    UNION
    SELECT s_store_id, s_state, amount FROM returns_2000
  ),
  stores_with_inventory AS (
    SELECT DISTINCT s.s_store_id
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN inventory i ON ss.ss_item_sk = i.inv_item_sk
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
  ),
  net_without_inventory AS (
    SELECT u.s_store_id,
           u.s_state,
           u.amount,
           (SELECT COUNT(*) FROM customer_address ca WHERE ca.ca_state = u.s_state) AS addr_cnt
    FROM union_amounts u
    EXCEPT
    SELECT si.s_store_id, NULL, NULL, NULL FROM stores_with_inventory si
  )
SELECT n.s_store_id,
       n.s_state,
       n.amount,
       n.addr_cnt,
       m.d_month_seq
FROM net_without_inventory n
CROSS JOIN (
  SELECT DISTINCT d_month_seq
  FROM date_dim
  WHERE d_year = 2000
) m
LIMIT 100
