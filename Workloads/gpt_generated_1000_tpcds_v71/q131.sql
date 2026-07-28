WITH joined_data AS (
  SELECT
    cr.cr_returning_customer_sk,
    cd_ret.cd_gender AS returning_gender,
    cr.cr_return_amount,
    ws.ws_ext_sales_price,
    d.d_year,
    t.t_hour,
    sm.sm_type,
    hd_ret.hd_vehicle_count,
    p.p_discount_active,
    ws_site.web_state
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  WHERE d.d_year = 1999
    AND t.t_hour BETWEEN 8 AND 12
    AND sm.sm_type = 'AIR'
    AND cd_ret.cd_gender = 'F'
    AND hd_ret.hd_vehicle_count > 1
    AND p.p_discount_active = 'Y'
    AND ws_site.web_state = 'CA'
)
SELECT
  cr_returning_customer_sk,
  returning_gender,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(ws_ext_sales_price) AS total_sales_price,
  COUNT(*) AS num_returns,
  CASE WHEN SUM(cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS return_category,
  RANK() OVER (ORDER BY SUM(cr_return_amount) DESC) AS return_amount_rank
FROM joined_data
GROUP BY cr_returning_customer_sk, returning_gender
ORDER BY return_amount_rank
LIMIT 100
