WITH joined_data AS (
  SELECT
    s.s_store_id,
    d.d_year,
    ss.ss_net_paid,
    ss.ss_net_profit,
    cr.cr_net_loss,
    sr.sr_net_loss,
    wr.wr_net_loss,
    p.p_discount_active,
    r.r_reason_desc,
    w.w_warehouse_id,
    ss.ss_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND s.s_state = 'CA'
    AND w.w_warehouse_id = 'AAAAAAAADBAAAAAA'
    AND p.p_discount_active = 'Y'
    AND r.r_reason_desc LIKE '%defect%'
    AND ss.ss_quantity > 5
    AND NOT EXISTS (
      SELECT 1 FROM web_returns wr2
      WHERE wr2.wr_order_number = cr.cr_order_number
    )
),
agg AS (
  SELECT
    s_store_id,
    d_year,
    SUM(ss_net_paid) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_return_loss,
    COUNT(*) AS txn_count,
    AVG(ss_quantity) AS avg_quantity
  FROM joined_data
  GROUP BY s_store_id, d_year
  HAVING SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) > 5000
)
SELECT
  s_store_id,
  d_year,
  total_sales,
  total_profit,
  total_return_loss,
  txn_count,
  avg_quantity,
  (total_return_loss / NULLIF(total_sales, 0)) AS loss_rate
FROM agg
WHERE total_sales > 10000
ORDER BY total_return_loss DESC
LIMIT 100
