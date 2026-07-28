WITH joined AS (
  SELECT
    d.d_year,
    d.d_holiday,
    c.c_birth_country,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    p.p_discount_active,
    sm.sm_type,
    cp.cp_department,
    s.s_store_name,
    s.s_state,
    ss.ss_net_paid,
    ss.ss_ticket_number,
    cs.cs_net_paid,
    ws.ws_net_paid,
    ws.ws_quantity
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_holiday = 'N'
    AND c.c_birth_country = 'MEXICO'
    AND hd.hd_vehicle_count >= 1
    AND ib.ib_upper_bound <= 50000
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND cp.cp_department = 'Electronics'
    AND s.s_state = 'CA'
    AND ws.ws_quantity > 5
),
agg AS (
  SELECT
    d_year,
    s_store_name,
    SUM(ss_net_paid) AS store_sales_total,
    COUNT(DISTINCT ss_ticket_number) AS transaction_count
  FROM joined
  GROUP BY d_year, s_store_name
)
SELECT
  d_year,
  s_store_name,
  store_sales_total,
  transaction_count,
  AVG(store_sales_total) OVER (PARTITION BY d_year) AS avg_store_sales_per_year
FROM agg
WHERE store_sales_total > 1000
ORDER BY d_year, store_sales_total DESC
LIMIT 100
