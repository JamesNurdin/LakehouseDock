WITH rc_base AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    dd.d_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_net_loss) AS avg_net_loss
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE dd.d_year = 2001
    AND cr.cr_return_amount > 0
    AND NOT EXISTS (
      SELECT 1
      FROM reason r2
      WHERE r2.r_reason_sk = cr.cr_reason_sk
        AND lower(r2.r_reason_desc) = 'damaged'
    )
  GROUP BY cc.cc_call_center_id, cc.cc_name, dd.d_year
  HAVING SUM(cr.cr_net_loss) > 0
),
rc_agg AS (
  SELECT
    cc_call_center_id,
    cc_name,
    d_year,
    total_net_loss,
    return_cnt,
    avg_net_loss,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_net_loss DESC) AS rn
  FROM rc_base
),
promo_agg AS (
  SELECT
    p.p_promo_name,
    dd_start.d_year AS start_year,
    dd_end.d_year AS end_year,
    p.p_cost AS promo_cost,
    CASE
      WHEN p.p_cost > 1000 THEN 'High'
      WHEN p.p_cost > 500 THEN 'Medium'
      ELSE 'Low'
    END AS cost_category
  FROM promotion p
  JOIN date_dim dd_start ON p.p_start_date_sk = dd_start.d_date_sk
  JOIN date_dim dd_end ON p.p_end_date_sk = dd_end.d_date_sk
  WHERE dd_start.d_year = 2001
    AND p.p_channel_catalog = 'Y'
)
SELECT
  rc.cc_call_center_id,
  rc.cc_name,
  rc.d_year,
  rc.total_net_loss,
  rc.return_cnt,
  rc.avg_net_loss,
  rc.rn AS rank_by_loss,
  CASE
    WHEN rc.total_net_loss > 1000 THEN 'High'
    WHEN rc.total_net_loss > 500 THEN 'Medium'
    ELSE 'Low'
  END AS loss_category,
  (SELECT AVG(total_net_loss) FROM rc_base) AS avg_loss_all_centers
FROM rc_agg rc

UNION ALL

SELECT
  NULL AS cc_call_center_id,
  p.p_promo_name AS cc_name,
  p.start_year AS d_year,
  p.promo_cost AS total_net_loss,
  NULL AS return_cnt,
  NULL AS avg_net_loss,
  NULL AS rank_by_loss,
  p.cost_category AS loss_category,
  (SELECT AVG(promo_cost) FROM promo_agg) AS avg_loss_all_centers
FROM promo_agg p

ORDER BY total_net_loss DESC
LIMIT 100
