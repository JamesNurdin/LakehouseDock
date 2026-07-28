WITH sales_agg AS (
  SELECT
    cs.cs_bill_customer_sk,
    d.d_year,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS order_cnt,
    CASE
      WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'HIGH'
      ELSE 'NORMAL'
    END AS sales_category,
    w.w_state,
    cc.cc_name,
    p.p_discount_active,
    ib.ib_lower_bound,
    wp.wp_type,
    ws.web_class
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND w.w_state = 'CA'
    AND cc.cc_name = 'Call Center 1'
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 50000
  GROUP BY cs.cs_bill_customer_sk, d.d_year, w.w_state, cc.cc_name, p.p_discount_active, ib.ib_lower_bound, wp.wp_type, ws.web_class
)

SELECT
  s.cs_bill_customer_sk AS customer_sk,
  s.d_year,
  s.total_sales,
  s.total_profit,
  s.order_cnt,
  s.sales_category,
  s.wp_type,
  s.web_class,
  RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank,
  (
    SELECT COUNT(*)
    FROM web_returns wr
    JOIN date_dim dwr ON wr.wr_returned_date_sk = dwr.d_date_sk
    WHERE dwr.d_year = s.d_year
      AND EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = wr.wr_reason_sk
          AND r.r_reason_desc LIKE '%time%'
      )
  ) AS returns_count_this_year
FROM sales_agg s
WHERE s.sales_category = 'HIGH'
ORDER BY s.total_sales DESC
LIMIT 100
