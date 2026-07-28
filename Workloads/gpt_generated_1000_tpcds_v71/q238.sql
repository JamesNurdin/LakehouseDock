WITH
  catalog_agg AS (
    SELECT
      'catalog' AS source_type,
      r.r_reason_desc AS reason_desc,
      t.t_shift AS period_shift,
      w.w_warehouse_name AS location,
      SUM(cr.cr_return_quantity) AS total_return_quantity,
      SUM(cr.cr_return_amount)   AS total_return_amount,
      SUM(cr.cr_net_loss)        AS total_net_loss
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk      = cs.cs_item_sk
     AND cr.cr_warehouse_sk = cs.cs_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY r.r_reason_desc, t.t_shift, w.w_warehouse_name
  ),
  store_agg AS (
    SELECT
      'store' AS source_type,
      r.r_reason_desc AS reason_desc,
      t.t_shift AS period_shift,
      s.s_store_name AS location,
      SUM(sr.sr_return_quantity) AS total_return_quantity,
      SUM(sr.sr_return_amt)     AS total_return_amount,
      SUM(sr.sr_net_loss)       AS total_net_loss
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc, t.t_shift, s.s_store_name
  ),
  web_agg AS (
    SELECT
      'web' AS source_type,
      r.r_reason_desc AS reason_desc,
      t.t_shift AS period_shift,
      NULL AS location,
      SUM(wr.wr_return_quantity) AS total_return_quantity,
      SUM(wr.wr_return_amt)      AS total_return_amount,
      SUM(wr.wr_net_loss)        AS total_net_loss
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc, t.t_shift
  ),
  combined_store_web AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
  )
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM combined_store_web
ORDER BY total_net_loss DESC
LIMIT 100
