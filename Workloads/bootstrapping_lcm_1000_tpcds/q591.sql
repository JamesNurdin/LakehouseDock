WITH store_monthly AS (
  SELECT
    s.s_store_id,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders,
    AVG(cd_ret_cr.cd_purchase_estimate) AS avg_returning_purchase_estimate_catalog,
    AVG(cd_ret_wr.cd_purchase_estimate) AS avg_returning_purchase_estimate_web,
    AVG(cd_ref_cr.cd_purchase_estimate) AS avg_refunded_purchase_estimate_catalog,
    AVG(cd_ref_wr.cd_purchase_estimate) AS avg_refunded_purchase_estimate_web
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  JOIN customer_demographics cd_ref_cr
    ON cr.cr_refunded_cdemo_sk = cd_ref_cr.cd_demo_sk
  JOIN customer_demographics cd_ret_cr
    ON cr.cr_returning_cdemo_sk = cd_ret_cr.cd_demo_sk
  JOIN customer_demographics cd_ref_wr
    ON wr.wr_refunded_cdemo_sk = cd_ref_wr.cd_demo_sk
  JOIN customer_demographics cd_ret_wr
    ON wr.wr_returning_cdemo_sk = cd_ret_wr.cd_demo_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY s.s_store_id, s.s_state, d.d_year, d.d_month_seq
  HAVING SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
)
SELECT
  sm.s_store_id,
  sm.s_state,
  sm.d_year,
  sm.d_month_seq,
  sm.catalog_net_loss,
  sm.web_net_loss,
  sm.total_net_loss,
  sm.catalog_orders,
  sm.web_orders,
  sm.avg_returning_purchase_estimate_catalog,
  sm.avg_returning_purchase_estimate_web,
  sm.avg_refunded_purchase_estimate_catalog,
  sm.avg_refunded_purchase_estimate_web,
  sm.total_net_loss / NULLIF(SUM(sm.total_net_loss) OVER (PARTITION BY sm.d_year, sm.d_month_seq), 0) AS store_loss_share,
  CASE
    WHEN sm.web_net_loss = 0 THEN NULL
    ELSE sm.catalog_net_loss / sm.web_net_loss
  END AS catalog_to_web_loss_ratio
FROM store_monthly sm
ORDER BY sm.s_store_id, sm.d_year, sm.d_month_seq
LIMIT 100
