WITH base AS (
  SELECT
    s.s_store_id,
    s.s_city,
    i.i_item_id,
    i.i_category,
    r.r_reason_id,
    cr.cr_return_amount,
    sr.sr_return_amt,
    ss.ss_net_paid,
    ss.ss_quantity,
    td.t_hour,
    sm.sm_carrier,
    w.w_gmt_offset,
    (
      SELECT sum(ss2.ss_net_paid)
      FROM store_sales ss2
      WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS store_total_net_paid
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE s.s_state = 'CA'
    AND i.i_category_id IN (3, 4, 7)
    AND sm.sm_carrier = 'UPS'
    AND w.w_gmt_offset BETWEEN -5 AND 5
    AND td.t_hour BETWEEN 9 AND 17
    AND r.r_reason_id LIKE 'AAAA%'
    AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr2
      WHERE cr2.cr_item_sk = i.i_item_sk
        AND cr2.cr_return_quantity > 10
    )
),

agg1 AS (
  SELECT
    s_store_id,
    i_item_id,
    r_reason_id,
    SUM(cr_return_amount) AS sum_return_amount,
    SUM(sr_return_amt) AS sum_store_return_amt,
    SUM(ss_net_paid) AS sum_net_paid,
    COUNT(*) AS txn_count
  FROM base
  GROUP BY ROLLUP (s_store_id, i_item_id, r_reason_id)
),

agg2 AS (
  SELECT
    s_store_id,
    AVG(sum_net_paid) AS avg_item_net_paid,
    SUM(sum_return_amount) AS total_return_amount
  FROM agg1
  WHERE sum_return_amount IS NOT NULL
  GROUP BY s_store_id
)

SELECT
  a2.s_store_id,
  a2.avg_item_net_paid,
  a2.total_return_amount,
  a1.r_reason_id,
  a1.sum_return_amount,
  ROW_NUMBER() OVER (PARTITION BY a2.s_store_id ORDER BY a1.sum_return_amount DESC) AS reason_rank,
  a2.avg_item_net_paid / NULLIF(a2.total_return_amount, 0) AS avg_ratio
FROM agg2 a2
JOIN agg1 a1 ON a1.s_store_id = a2.s_store_id
WHERE a1.r_reason_id IS NOT NULL
ORDER BY a2.total_return_amount DESC, a2.s_store_id
LIMIT 100
