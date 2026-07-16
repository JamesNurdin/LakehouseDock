WITH aggregated AS (
  SELECT
    cr.cr_returned_date_sk,
    dr_return.d_year,
    dr_return.d_quarter_name,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
  FROM catalog_returns cr
  JOIN date_dim dr_return
    ON cr.cr_returned_date_sk = dr_return.d_date_sk
  JOIN promotion p
    ON dr_return.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  JOIN date_dim dr_promo_start
    ON dr_promo_start.d_date_sk = p.p_start_date_sk
  JOIN date_dim dr_promo_end
    ON dr_promo_end.d_date_sk = p.p_end_date_sk
  JOIN date_dim dr_store
    ON dr_store.d_date_sk = dr_return.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = dr_store.d_date_sk
  JOIN date_dim dr_ws_open
    ON dr_ws_open.d_date_sk = dr_return.d_date_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = dr_ws_open.d_date_sk
  JOIN date_dim dr_ws_close
    ON dr_ws_close.d_date_sk = ws.web_close_date_sk
  WHERE dr_return.d_year BETWEEN 2020 AND 2022
    AND p.p_cost > 1000
    AND s.s_state = 'CA'
    AND ws.web_state = 'CA'
  GROUP BY
    cr.cr_returned_date_sk,
    dr_return.d_year,
    dr_return.d_quarter_name,
    p.p_promo_id,
    p.p_promo_name,
    p.p_cost,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws.web_site_id,
    ws.web_name,
    ws.web_city,
    ws.web_state
  HAVING SUM(cr.cr_return_amount) > 5000
)
SELECT
  cr_returned_date_sk,
  d_year,
  d_quarter_name,
  p_promo_id,
  p_promo_name,
  p_cost,
  s_store_id,
  s_store_name,
  s_city,
  s_state,
  web_site_id,
  web_name,
  web_city,
  web_state,
  total_return_amount,
  total_net_loss,
  return_count,
  avg_return_quantity,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rn_yearly_return_amount
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
