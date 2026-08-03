WITH
  filtered AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_return_tax,
      cr.cr_refunded_customer_sk,
      cr.cr_reason_sk,
      cr.cr_order_number,
      d.d_date,
      d.d_year,
      d.d_month_seq,
      c.c_customer_id,
      c.c_preferred_cust_flag,
      r.r_reason_desc,
      i.inv_quantity_on_hand,
      i.inv_warehouse_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND c.c_preferred_cust_flag = 'Y'
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND i.inv_quantity_on_hand > 100
      AND cr.cr_return_amount > 100.0
      AND d.d_month_seq BETWEEN 1200 AND 1300
  ),
  base AS (
    SELECT
      f.c_customer_id,
      f.r_reason_desc,
      SUM(f.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt
    FROM filtered f
    GROUP BY GROUPING SETS (
      (f.c_customer_id, f.r_reason_desc),
      (f.c_customer_id),
      (f.r_reason_desc),
      ()
    )
  ),
  ranked AS (
    SELECT
      b.c_customer_id,
      b.r_reason_desc,
      b.total_return_amount,
      b.return_cnt,
      CASE
        WHEN b.total_return_amount > (SELECT AVG(cr_return_amount) FROM catalog_returns)
        THEN 'Above Avg'
        ELSE 'Below Avg'
      END AS amount_category,
      ROW_NUMBER() OVER (PARTITION BY b.c_customer_id ORDER BY b.total_return_amount DESC) AS rn
    FROM base b
    WHERE b.c_customer_id IS NOT NULL
  )
SELECT
  r.c_customer_id,
  r.r_reason_desc,
  r.total_return_amount,
  r.return_cnt,
  r.amount_category,
  r.rn
FROM ranked r
WHERE r.rn <= 5
ORDER BY r.c_customer_id, r.rn
LIMIT 100
