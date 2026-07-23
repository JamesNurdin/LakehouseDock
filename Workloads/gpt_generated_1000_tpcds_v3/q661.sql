-- goal: Compare recent catalog sales and store returns per customer, showing sales vs returns with amounts, extra info, and per‑customer transaction counts, ordered by amount.
WITH
  sales AS (
    SELECT
      c.c_customer_id AS customer_id,
      'sale' AS transaction_type,
      cs.cs_ext_sales_price AS transaction_amount,
      cs.cs_sold_date_sk AS transaction_date_sk,
      cc.cc_name AS extra_info,
      (
        SELECT COUNT(*)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
          AND cs2.cs_ext_sales_price > 0
      ) AS transaction_count
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND cs.cs_ext_ship_cost > 400
      AND c.c_birth_month IN (5, 7, 9)
  ),
  returns AS (
    SELECT
      c.c_customer_id AS customer_id,
      'return' AS transaction_type,
      sr.sr_return_amt AS transaction_amount,
      sr.sr_returned_date_sk AS transaction_date_sk,
      r.r_reason_desc AS extra_info,
      (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > 0
      ) AS transaction_count
    FROM store_returns sr
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 0
      AND c.c_birth_month IN (5, 7, 9)
      AND EXISTS (
        SELECT 1
        FROM catalog_sales cs3
        WHERE cs3.cs_bill_customer_sk = c.c_customer_sk
          AND cs3.cs_ext_sales_price > 200
      )
  )
SELECT *
FROM (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
) combined
ORDER BY transaction_amount DESC, transaction_type, customer_id
LIMIT 100
