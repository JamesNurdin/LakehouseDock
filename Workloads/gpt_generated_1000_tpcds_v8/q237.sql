WITH base_data AS (
  SELECT
    sr.sr_return_amt,
    sr.sr_return_tax,
    sr.sr_fee,
    sr.sr_net_loss,
    cs.cs_net_paid,
    cs.cs_quantity,
    c.c_customer_sk,
    c.c_customer_id,
    cd.cd_gender,
    s.s_store_id,
    s.s_state,
    r.r_reason_desc,
    cc.cc_name,
    cp.cp_type,
    sm.sm_contract,
    w.w_warehouse_name,
    p.p_purpose,
    wr.wr_return_amt,
    wr.wr_fee,
    wr.wr_net_loss,
    t.channel_detail
  FROM store_returns sr
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
  CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel_detail)
  WHERE s.s_state = 'CA'
    AND cd.cd_gender = 'F'
    AND p.p_purpose = 'Unknown'
    AND sm.sm_contract = 'GNJr3g5i7oorKqtX'
),
union_returns AS (
  SELECT r.r_reason_desc AS reason, sr.sr_return_amt AS amount, 'store' AS src
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc = 'Damaged'
  UNION ALL
  SELECT r.r_reason_desc AS reason, wr.wr_return_amt AS amount, 'web' AS src
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE r.r_reason_desc = 'Damaged'
),
agg_data AS (
  SELECT
    s_store_id,
    r_reason_desc,
    COUNT(*) AS cnt_transactions,
    SUM(sr_return_amt) AS total_store_return,
    SUM(cs_net_paid) AS total_sales_paid,
    AVG(avg_qty_per_customer) AS avg_qty_customer,
    SUM(union_amount) AS total_union_amount,
    MIN(sr_return_tax) AS min_return_tax,
    MAX(p_purpose) AS max_purpose
  FROM (
    SELECT
      bd.s_store_id,
      bd.r_reason_desc,
      bd.sr_return_amt,
      bd.cs_net_paid,
      bd.sr_return_tax,
      bd.p_purpose,
      ur.amount AS union_amount,
      (
        SELECT AVG(cs2.cs_quantity)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = bd.c_customer_sk
      ) AS avg_qty_per_customer
    FROM base_data bd
    LEFT JOIN union_returns ur ON ur.reason = bd.r_reason_desc
  ) sub
  GROUP BY GROUPING SETS (
    (s_store_id, r_reason_desc),
    (s_store_id),
    (r_reason_desc)
  )
)
SELECT
  s_store_id,
  r_reason_desc,
  cnt_transactions,
  total_store_return,
  total_sales_paid,
  avg_qty_customer,
  total_union_amount,
  min_return_tax,
  max_purpose,
  ROW_NUMBER() OVER (ORDER BY total_store_return DESC) AS store_rank
FROM agg_data
ORDER BY total_store_return DESC
LIMIT 100
