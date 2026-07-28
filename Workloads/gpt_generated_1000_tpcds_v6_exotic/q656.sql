WITH sales_data AS (
  SELECT
    cp.cp_department AS department,
    d_sold.d_year        AS year,
    SUM(cs.cs_ext_sales_price)   AS total_sales,
    SUM(cs.cs_net_profit)        AS total_profit,
    AVG(ib.ib_lower_bound)       AS avg_income_lower,
    AVG(ib.ib_upper_bound)       AS avg_income_upper,
    ws.web_name                  AS web_name
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
  JOIN date_dim d_promo_end   ON p.p_end_date_sk   = d_promo_end.d_date_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
  JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
  WHERE cp.cp_type = 'PROMO'
    AND p.p_discount_active = 'Y'
    AND d_sold.d_year = 2001
    AND EXISTS (
      SELECT 1 FROM promotion p2
      WHERE p2.p_promo_sk = cs.cs_promo_sk
        AND p2.p_channel_tv = 'Y'
    )
  GROUP BY cp.cp_department, d_sold.d_year, ws.web_name
),

returns_data AS (
  SELECT
    r.r_reason_desc    AS department,
    d_return.d_year    AS year,
    SUM(wr.wr_return_amt) AS total_sales,
    -SUM(wr.wr_net_loss)  AS total_profit,
    AVG(ib.ib_lower_bound) AS avg_income_lower,
    AVG(ib.ib_upper_bound) AS avg_income_upper,
    ws.web_name            AS web_name
  FROM web_returns wr
  JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
  JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws ON ws.web_open_date_sk = d_return.d_date_sk
  JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
  JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
  JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
  JOIN income_band ib ON hd_refund.hd_income_band_sk = ib.ib_income_band_sk
  WHERE r.r_reason_desc LIKE '%size%'
    AND d_return.d_year = 2001
  GROUP BY r.r_reason_desc, d_return.d_year, ws.web_name
)

SELECT
  department,
  year,
  total_sales,
  total_profit,
  avg_income_lower,
  avg_income_upper,
  web_name,
  ROW_NUMBER() OVER (PARTITION BY department ORDER BY total_profit DESC) AS profit_rank
FROM (
  SELECT * FROM sales_data
  UNION ALL
  SELECT * FROM returns_data
) all_data
WHERE total_sales > (
  SELECT AVG(cs.cs_ext_sales_price)
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk IN (
    SELECT d_date_sk FROM date_dim WHERE d_year = 2001
  )
)
ORDER BY total_profit DESC
LIMIT 100
