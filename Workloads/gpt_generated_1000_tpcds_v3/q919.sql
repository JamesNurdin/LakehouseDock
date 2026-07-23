WITH base AS (
  SELECT
    d.d_year,
    ca.ca_state,
    CASE
      WHEN cr.cr_net_loss > 1000 THEN 'High'
      WHEN cr.cr_net_loss > 0 THEN 'Medium'
      ELSE 'Low'
    END AS net_loss_category,
    cr.cr_net_loss,
    cr.cr_return_amount,
    i.inv_quantity_on_hand
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ca.ca_state = 'CA'
    AND cr.cr_net_loss > 0
    AND i.inv_quantity_on_hand > 0
    AND p.p_discount_active = 'Y'
)
SELECT
  d_year,
  ca_state,
  net_loss_category,
  COUNT(*) AS return_cnt,
  SUM(cr_net_loss) AS total_net_loss,
  AVG(cr_return_amount) AS avg_return_amount,
  SUM(inv_quantity_on_hand) AS total_inventory_on_hand
FROM base
GROUP BY d_year, ca_state, net_loss_category
HAVING SUM(cr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
