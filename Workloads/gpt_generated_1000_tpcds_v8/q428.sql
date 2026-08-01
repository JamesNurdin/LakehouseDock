/*
Goal: Analyze return performance by promotion, focusing on customers who have returned items in stores but never returned them online. The query joins all eight TPC‑DS tables, applies realistic filters, samples web sales, uses EXCEPT to find exclusive store‑return customers, unions store and web returns, aggregates with distinct counts, and ranks promotions by total return amount using a window function.
*/
WITH
  -- Store returns enriched with customer, item, promotion and reason details
  sr_base AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      i.i_item_sk,
      i.i_item_id,
      sr.sr_return_amt,
      sr.sr_net_loss,
      p.p_promo_name,
      r.r_reason_desc
    FROM store_returns sr
    JOIN customer c            ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i                ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p           ON p.p_item_sk = i.i_item_sk
    JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month = 7
      AND i.i_brand = 'Brand#23'
      AND p.p_channel_tv = 'N'
      AND sr.sr_return_quantity > 1
  ),

  -- Web returns enriched with sales, customer, item, promotion and reason details; web_sales is sampled
  wr_base AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      i.i_item_sk,
      i.i_item_id,
      wr.wr_return_amt,
      wr.wr_net_loss,
      p.p_promo_name,
      r.r_reason_desc,
      ws.ws_sold_date_sk
    FROM web_returns wr
    JOIN web_sales ws TABLESAMPLE BERNOULLI (10) ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c            ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i                ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p           ON p.p_item_sk = i.i_item_sk
    JOIN reason r              ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
      AND c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month = 7
      AND i.i_brand = 'Brand#23'
      AND p.p_channel_tv = 'N'
  ),

  -- Union of store and web returns (deduped)
  union_returns AS (
    SELECT
      c_customer_id,
      i_item_id,
      sr_return_amt AS return_amt,
      sr_net_loss   AS net_loss,
      p_promo_name,
      r_reason_desc
    FROM sr_base
    UNION DISTINCT
    SELECT
      c_customer_id,
      i_item_id,
      wr_return_amt AS return_amt,
      wr_net_loss   AS net_loss,
      p_promo_name,
      r_reason_desc
    FROM wr_base
  ),

  -- Customers that appear in store_returns but never in web_returns
  exclusive_store_cust AS (
    SELECT c.c_customer_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    EXCEPT
    SELECT c.c_customer_sk
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  )

SELECT
  ur.p_promo_name,
  COUNT(DISTINCT ur.c_customer_id) AS distinct_customers,
  COUNT(DISTINCT ur.i_item_id)    AS distinct_items,
  SUM(ur.return_amt)              AS total_return_amount,
  AVG(ur.net_loss)                AS avg_net_loss,
  MIN(ur.return_amt)              AS min_return,
  MAX(ur.return_amt)              AS max_return,
  ROW_NUMBER() OVER (ORDER BY SUM(ur.return_amt) DESC) AS promo_rank
FROM union_returns ur
WHERE EXISTS (
        SELECT 1
        FROM customer c
        JOIN exclusive_store_cust esc ON c.c_customer_sk = esc.c_customer_sk
        WHERE c.c_customer_id = ur.c_customer_id
      )
GROUP BY ur.p_promo_name
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 20
