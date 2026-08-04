WITH base AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_return_time_sk,
    sr.sr_item_sk,
    sr.sr_hdemo_sk,
    sr.sr_reason_sk,
    sr.sr_refunded_cash,
    sr.sr_return_amt,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    i.i_item_sk,
    i.i_formulation,
    i.i_manufact_id,
    i.i_manager_id,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    r.r_reason_desc,
    p.p_promo_sk,
    p.p_discount_active,
    p.p_response_target,
    la.avg_refund_by_item
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
   AND p.p_start_date_sk = d.d_date_sk
   AND p.p_end_date_sk = d.d_date_sk
  CROSS JOIN LATERAL (
    SELECT AVG(sr2.sr_refunded_cash) AS avg_refund_by_item
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = sr.sr_item_sk
  ) AS la
  WHERE d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1210
    AND i.i_formulation LIKE '%moccasin%'
    AND i.i_manufact_id IN (214, 294)
    AND hd.hd_income_band_sk BETWEEN 5 AND 10
    AND sr.sr_refunded_cash > 100
    AND p.p_discount_active = 'Y'
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk
        AND p2.p_start_date_sk = d.d_date_sk
        AND p2.p_promo_sk <> p.p_promo_sk
    )
    AND NOT EXISTS (
      SELECT 1 FROM promotion p3
      WHERE p3.p_item_sk = i.i_item_sk
        AND p3.p_start_date_sk = d.d_date_sk
        AND p3.p_discount_active = 'N'
    )
),
agg1 AS (
  SELECT
    i_item_sk,
    d_year,
    r_reason_desc,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_refunded_cash) AS avg_refunded_cash,
    COUNT(*) AS return_cnt,
    MAX(t_hour) AS max_return_hour,
    AVG(avg_refund_by_item) AS avg_refund_by_item_over_rows
  FROM base
  GROUP BY i_item_sk, d_year, r_reason_desc
  HAVING SUM(sr_return_amt) > 500
),
agg2 AS (
  SELECT
    d_year,
    AVG(total_return_amt) AS avg_total_return_amt
  FROM agg1
  GROUP BY d_year
),
item_set1 AS (
  SELECT i_item_sk FROM base WHERE i_manager_id = 23
),
item_set2 AS (
  SELECT i_item_sk FROM base WHERE hd_vehicle_count > 2
),
intersection AS (
  SELECT i_item_sk FROM item_set1
  INTERSECT
  SELECT i_item_sk FROM item_set2
)
SELECT
  a1.i_item_sk,
  a1.d_year,
  a1.r_reason_desc,
  a1.total_return_amt,
  a1.avg_refunded_cash,
  a1.return_cnt,
  a1.max_return_hour,
  a2.avg_total_return_amt
FROM agg1 a1
JOIN agg2 a2 ON a1.d_year = a2.d_year
WHERE a1.i_item_sk IN (SELECT i_item_sk FROM intersection)
ORDER BY a1.total_return_amt DESC
LIMIT 100
