WITH
  item_agg AS (
    SELECT
      i_item_sk,
      COUNT(*) AS total_returns,
      SUM(wr_return_amt) AS sum_return_amt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i_item_sk
  ),
  customer_intersect AS (
    SELECT c_customer_sk FROM customer WHERE c_birth_year >= 1970
    INTERSECT
    SELECT wr_refunded_customer_sk FROM web_returns
  ),
  union_ret AS (
    SELECT r.r_reason_desc AS label,
           SUM(wr.wr_return_amt) AS total_amt,
           'reason' AS src
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
    UNION
    SELECT p.p_promo_name AS label,
           SUM(wr.wr_return_amt) AS total_amt,
           'promotion' AS src
    FROM web_returns wr
    JOIN promotion p ON wr.wr_item_sk = p.p_item_sk
    GROUP BY p.p_promo_name
  )
SELECT
  d_return.d_year,
  i.i_item_id,
  i.i_product_name,
  CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_category,
  ia.total_returns,
  p.p_promo_name,
  cp.cp_description,
  r.r_reason_desc,
  EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
      AND p2.p_start_date_sk <= d_return.d_date_sk
      AND p2.p_end_date_sk   >= d_return.d_date_sk
  ) AS promo_active,
  (SELECT COUNT(*) FROM customer_intersect) AS intersect_customer_count,
  COUNT(*) AS return_rows,
  SUM(wr.wr_return_amt) AS total_return_amount,
  AVG(wr.wr_return_tax) AS avg_return_tax,
  ur.total_amt AS union_total_amt,
  u.flag
FROM web_returns wr
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
FULL OUTER JOIN date_dim d_catalog
  ON d_return.d_date_sk = d_catalog.d_date_sk
JOIN time_dim t
  ON wr.wr_returned_time_sk = t.t_time_sk
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
LEFT JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_catalog.d_date_sk
     OR cp.cp_end_date_sk = d_catalog.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer crf
  ON wr.wr_refunded_customer_sk = crf.c_customer_sk
JOIN customer crg
  ON wr.wr_returning_customer_sk = crg.c_customer_sk
JOIN customer_demographics cd_refunded
  ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
  ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN customer_address ca_refunded
  ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
  ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
LEFT JOIN item_agg ia
  ON i.i_item_sk = ia.i_item_sk
LEFT JOIN union_ret ur
  ON ur.label = r.r_reason_desc OR ur.label = p.p_promo_name
CROSS JOIN UNNEST(ARRAY['A', 'B']) AS u(flag)
WHERE d_return.d_year BETWEEN 2000 AND 2002
GROUP BY
  d_return.d_year,
  i.i_item_id,
  i.i_product_name,
  CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END,
  ia.total_returns,
  p.p_promo_name,
  cp.cp_description,
  r.r_reason_desc,
  EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_item_sk = i.i_item_sk
      AND p2.p_start_date_sk <= d_return.d_date_sk
      AND p2.p_end_date_sk   >= d_return.d_date_sk
  ),
  (SELECT COUNT(*) FROM customer_intersect),
  ur.total_amt,
  u.flag
ORDER BY total_return_amount DESC
LIMIT 100
