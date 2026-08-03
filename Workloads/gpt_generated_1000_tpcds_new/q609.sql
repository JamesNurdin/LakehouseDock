WITH returned_data AS (
   SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_warehouse_sk,
      cr.cr_reason_sk,
      d_ret.d_year,
      d_ret.d_month_seq,
      t.t_hour,
      cd.cd_credit_rating,
      hd.hd_income_band_sk,
      cc.cc_name,
      cp.cp_department,
      w.w_warehouse_name,
      r.r_reason_desc
   FROM catalog_returns cr
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN (SELECT * FROM call_center TABLESAMPLE BERNOULLI (10)) cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cc.cc_gmt_offset > -5
),
store_data AS (
   SELECT
      s.s_store_sk,
      s.s_store_name,
      d_store.d_date_sk   AS store_date_sk,
      d_store.d_year      AS store_year,
      s.s_city
   FROM store s
   JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
),
website_data AS (
   SELECT
      ws.web_site_sk,
      ws.web_name,
      d_web.d_date_sk    AS web_date_sk,
      d_web.d_year       AS web_year,
      ws.web_city
   FROM web_site ws
   JOIN date_dim d_web ON ws.web_close_date_sk = d_web.d_date_sk
),
joined_dim AS (
   SELECT
      sd.s_store_sk,
      wd.web_site_sk,
      sd.store_date_sk,
      sd.store_year
   FROM store_data sd
   FULL OUTER JOIN website_data wd
     ON sd.store_date_sk = wd.web_date_sk
),
filtered_orders AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_amount > 500
   EXCEPT
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_tax > 50
)
SELECT
   rd.d_year,
   rd.cc_name,
   rd.cp_department,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   COUNT(DISTINCT rd.cr_order_number)                AS distinct_orders,
   SUM(rd.cr_return_amount)                         AS total_return_amount,
   SUM(SUM(rd.cr_return_amount)) OVER (
        PARTITION BY rd.cc_name
        ORDER BY rd.d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   )                                                AS running_total_return
FROM returned_data rd
JOIN household_demographics hd2 ON rd.hd_income_band_sk = hd2.hd_income_band_sk
JOIN income_band ib ON hd2.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN joined_dim jd ON rd.d_year = jd.store_year
WHERE rd.cr_order_number NOT IN (
      SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 2000
   )
  AND rd.cr_order_number IN (SELECT cr_order_number FROM filtered_orders)
GROUP BY
   rd.d_year,
   rd.cc_name,
   rd.cp_department,
   ib.ib_lower_bound,
   ib.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
