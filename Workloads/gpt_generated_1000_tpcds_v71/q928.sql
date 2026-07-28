WITH filtered_returns AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_store_credit,
       cr.cr_reversed_charge,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cr.cr_fee,
       cr.cr_return_ship_cost,
       cr.cr_order_number,
       cr.cr_item_sk
   FROM catalog_returns cr
   WHERE cr.cr_store_credit > 100
     AND cr.cr_reversed_charge < 500
     AND cr.cr_return_amount BETWEEN 10 AND 5000
     AND cr.cr_return_quantity >= 1
     AND cr.cr_fee IS NOT NULL
),
store_with_tax AS (
   SELECT
       s.s_store_sk,
       s.s_store_id,
       s.s_company_id,
       s.s_division_id,
       s.s_tax_percentage,
       s.s_closed_date_sk
   FROM store s
   WHERE s.s_tax_percentage > 0
     AND s.s_company_id = 1
     AND s.s_division_id = 1
),
date_filtered AS (
   SELECT
       d.d_date_sk,
       d.d_year,
       d.d_fy_quarter_seq,
       d.d_month_seq,
       d.d_date
   FROM date_dim d
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND d.d_fy_quarter_seq IN (2, 5, 10, 12, 16)
)
SELECT
    s.s_store_id,
    d.d_year,
    d.d_fy_quarter_seq,
    SUM(fr.cr_return_amount)                         AS total_return_amount,
    SUM(fr.cr_store_credit)                         AS total_store_credit,
    COUNT(DISTINCT fr.cr_order_number)              AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(fr.cr_return_amount) DESC) AS rn_store_by_return,
    RANK()      OVER (PARTITION BY d.d_year ORDER BY SUM(fr.cr_return_amount) DESC)      AS rank_yearly_return
FROM filtered_returns fr
JOIN date_filtered d
  ON fr.cr_returned_date_sk = d.d_date_sk
JOIN store_with_tax s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM store s2
    WHERE s2.s_store_id = s.s_store_id
      AND s2.s_tax_percentage >= 0.05
)
GROUP BY ROLLUP (s.s_store_id, d.d_year, d.d_fy_quarter_seq)
HAVING SUM(fr.cr_return_amount) > 1000
   AND COUNT(fr.cr_order_number) >= 5
ORDER BY total_return_amount DESC
LIMIT 100
