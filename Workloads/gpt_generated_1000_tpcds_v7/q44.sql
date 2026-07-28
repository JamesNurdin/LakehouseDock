WITH joined_data AS (
  SELECT
    td.t_hour AS hour_of_day,
    w.w_warehouse_name AS warehouse_name,
    ws_site.web_name AS site_name,
    cr.cr_return_amount AS return_amount,
    ws.ws_ext_sales_price AS sales_price,
    ws.ws_quantity AS quantity
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
                    AND ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  WHERE cr.cr_return_amount > 0
    AND ws.ws_quantity > 0
    AND ib.ib_lower_bound >= 100000
    AND r.r_reason_desc LIKE '%product%'
    AND td.t_hour BETWEEN 9 AND 17
)
SELECT
  hour_of_day,
  warehouse_name,
  site_name,
  SUM(return_amount) AS total_return_amount,
  AVG(sales_price) AS avg_sales_price,
  SUM(quantity) AS total_quantity,
  SUM(SUM(return_amount)) OVER (PARTITION BY warehouse_name ORDER BY hour_of_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_return_by_warehouse,
  RANK() OVER (ORDER BY SUM(return_amount) DESC) AS return_rank
FROM joined_data
GROUP BY hour_of_day, warehouse_name, site_name
ORDER BY total_return_amount DESC
LIMIT 100
