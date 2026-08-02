/*
  Goal: Summarize web return performance by item brand, category, and time shift, including totals and subtotals using ROLLUP, while showing distinct return reasons, active promotion stats, and handling unmatched rows via FULL OUTER and LEFT joins.
*/
SELECT
  i1.i_brand,
  i1.i_category,
  t1.t_shift,
  SUM(wr.wr_return_amt)                     AS total_return_amount,
  SUM(wr.wr_return_tax)                    AS total_return_tax,
  COUNT(DISTINCT wr.wr_order_number)       AS distinct_orders,
  COUNT(DISTINCT r1.r_reason_desc)         AS distinct_return_reasons,
  (
    SELECT MAX(p_sub.p_cost)
    FROM promotion p_sub
    JOIN item i_sub
      ON p_sub.p_item_sk = i_sub.i_item_sk
    WHERE i_sub.i_brand   = i1.i_brand
      AND i_sub.i_category = i1.i_category
  )                                          AS max_promo_cost,
  (
    SELECT COUNT(DISTINCT p_sub2.p_promo_name)
    FROM promotion p_sub2
    JOIN item i_sub2
      ON p_sub2.p_item_sk = i_sub2.i_item_sk
    WHERE i_sub2.i_brand   = i1.i_brand
      AND i_sub2.i_category = i1.i_category
  )                                          AS promo_name_count
FROM web_returns wr
  JOIN item i1
    ON wr.wr_item_sk = i1.i_item_sk
  LEFT JOIN reason r1
    ON wr.wr_reason_sk = r1.r_reason_sk
  JOIN time_dim t1
    ON wr.wr_returned_time_sk = t1.t_time_sk
  FULL OUTER JOIN promotion p
    ON p.p_item_sk = i1.i_item_sk
  JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
  JOIN time_dim t2
    ON wr.wr_returned_time_sk = t2.t_time_sk
  JOIN item i2
    ON wr.wr_item_sk = i2.i_item_sk
  LEFT JOIN promotion p2
    ON p2.p_item_sk = i2.i_item_sk
  LEFT JOIN reason r3
    ON wr.wr_reason_sk = r3.r_reason_sk
WHERE EXISTS (
        SELECT 1
        FROM promotion p_check
        WHERE p_check.p_item_sk = i1.i_item_sk
          AND p_check.p_discount_active = 'Y'
      )
GROUP BY ROLLUP (i1.i_brand, i1.i_category, t1.t_shift)
ORDER BY
  i1.i_brand,
  i1.i_category,
  t1.t_shift,
  total_return_amount DESC
LIMIT 100
