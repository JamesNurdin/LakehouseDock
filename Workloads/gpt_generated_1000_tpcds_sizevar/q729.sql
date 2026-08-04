/*
Goal: Identify high‑value customers who bought promoted items in 2001, had at least one web return, but did not purchase large quantities (>5) in store sales. The query demonstrates deep joins across all 11 tables, uses CTE pre‑aggregation, UNION, INTERSECT, EXCEPT, an anti‑join (NOT EXISTS), a correlated scalar sub‑query, and a ranking window function. Results are ordered by total sales and limited to the top 100 rows.
*/
WITH
  -- Pre‑aggregate inventory by item and warehouse
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  -- Store‑sales customers for promoted items in 2001
  store_set AS (
    SELECT
      ss.ss_customer_sk   AS cust_sk,
      ss.ss_item_sk       AS item_sk,
      ss.ss_sold_date_sk  AS date_sk,
      ss.ss_promo_sk      AS promo_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
  ),
  -- Web‑sales customers for promoted items in 2001
  web_set AS (
    SELECT
      ws.ws_bill_customer_sk AS cust_sk,
      ws.ws_item_sk          AS item_sk,
      ws.ws_sold_date_sk    AS date_sk,
      ws.ws_promo_sk        AS promo_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
  ),
  -- Union of both sales sources (distinct rows)
  union_set AS (
    SELECT cust_sk, item_sk, date_sk, promo_sk FROM store_set
    UNION
    SELECT cust_sk, item_sk, date_sk, promo_sk FROM web_set
  ),
  -- Customers that have at least one web return
  return_set AS (
    SELECT DISTINCT wr.wr_refunded_customer_sk AS cust_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
  ),
  -- Keep only customers that appear in both the union set and the return set
  intersect_set AS (
    SELECT u.cust_sk,
           u.item_sk,
           u.date_sk,
           u.promo_sk
    FROM union_set u
    INTERSECT
    SELECT r.cust_sk,
           CAST(NULL AS integer) AS item_sk,
           CAST(NULL AS integer) AS date_sk,
           CAST(NULL AS integer) AS promo_sk
    FROM return_set r
  ),
  -- Remove any rows that correspond to store‑sales records with zero quantity (demonstrates EXCEPT)
  final_keys AS (
    SELECT i.cust_sk,
           i.item_sk,
           i.date_sk,
           i.promo_sk
    FROM intersect_set i
    EXCEPT
    SELECT ss.ss_customer_sk,
           ss.ss_item_sk,
           ss.ss_sold_date_sk,
           ss.ss_promo_sk
    FROM store_sales ss
    WHERE ss.ss_quantity = 0
  ),
  -- Total sales per customer (pre‑aggregation for later join)
  sales_total AS (
    SELECT
      c.c_customer_sk AS cust_sk,
      SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales
    FROM customer c
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws   ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ca.ca_city,
  i.i_product_name,
  d.d_date,
  p.p_promo_name,
  w.w_warehouse_name,
  ia.total_on_hand,
  st.total_sales,
  -- Correlated scalar sub‑query: total refunded amount per customer
  (
    SELECT SUM(wr2.wr_return_amt)
    FROM web_returns wr2
    WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
  ) AS total_refund_amount,
  -- Ranking of customers by total sales (window function)
  ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY st.total_sales DESC) AS sales_rank
FROM final_keys fk
JOIN customer c               ON fk.cust_sk = c.c_customer_sk
JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
JOIN date_dim d               ON fk.date_sk = d.d_date_sk
JOIN promotion p              ON fk.promo_sk = p.p_promo_sk
JOIN item i                   ON fk.item_sk = i.i_item_sk
JOIN inv_agg ia               ON i.i_item_sk = ia.inv_item_sk
JOIN warehouse w              ON ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_site wsit            ON d.d_date_sk = wsit.web_open_date_sk
LEFT JOIN sales_total st      ON c.c_customer_sk = st.cust_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk
          AND ss2.ss_quantity > 5
      )
ORDER BY st.total_sales DESC, sales_rank ASC
LIMIT 100
