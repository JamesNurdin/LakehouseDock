WITH sales_shipmode AS (
   SELECT
     cs.cs_order_number,
     cs.cs_sold_date_sk,
     cs.cs_sold_time_sk,
     cs.cs_ship_mode_sk,
     cs.cs_quantity,
     cs.cs_net_paid,
     cs.cs_bill_addr_sk,
     cs.cs_ship_addr_sk,
     cs.cs_bill_hdemo_sk,
     cs.cs_ship_hdemo_sk,
     cs.cs_call_center_sk,
     cs.cs_catalog_page_sk,
     cs.cs_promo_sk,
     sm.sm_ship_mode_id,
     sm.sm_type,
     d.d_year,
     d.d_month_seq,
     t.t_hour
   FROM catalog_sales cs
   RIGHT JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   WHERE (d.d_year BETWEEN 1999 AND 2001 OR d.d_year IS NULL)
     AND sm.sm_type IS NOT NULL
     AND (cs.cs_net_paid > 1000 OR cs.cs_net_paid IS NULL)
     AND (cs.cs_quantity BETWEEN 1 AND 100 OR cs.cs_quantity IS NULL)
     AND (cs.cs_sold_date_sk IS NOT NULL OR cs.cs_sold_date_sk IS NULL)
),
joined_data AS (
   SELECT
     ss.sm_ship_mode_id            AS sm_id,
     ss.d_year                     AS year,
     ss.d_month_seq                AS month_seq,
     COALESCE(ss.cs_net_paid, 0)   AS total_sales,
     COALESCE(ss.cs_quantity, 0)   AS total_quantity,
     CASE WHEN ss.cs_quantity = 0 THEN 0
          ELSE COALESCE(ss.cs_net_paid, 0) / ss.cs_quantity END AS avg_net_paid,
     ca.ca_city,
     ca.ca_state,
     hd.hd_income_band_sk,
     cc.cc_name,
     cp.cp_catalog_page_number,
     p.p_promo_name,
     wr.wr_return_amt,
     wp.wp_url,
     ws.web_state
   FROM sales_shipmode ss
   LEFT JOIN customer_address ca
     ON ss.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN household_demographics hd
     ON ss.cs_bill_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN call_center cc
     ON ss.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp
     ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN promotion p
     ON ss.cs_promo_sk = p.p_promo_sk
   LEFT JOIN web_returns wr
     ON ss.cs_sold_date_sk = wr.wr_returned_date_sk
   LEFT JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_site ws
     ON wp.wp_creation_date_sk = ws.web_open_date_sk
   -- expand address components with UNNEST
   LEFT JOIN UNNEST(ARRAY[ca.ca_city, ca.ca_state]) AS t(loc) ON TRUE
   WHERE cp.cp_catalog_page_number IN (7, 14, 16, 18, 19)
     AND cc.cc_state = 'CA'
     AND ws.web_state IN ('LA', 'MI', 'NC')
     AND p.p_promo_name IS NOT NULL
     AND wr.wr_return_amt > 0
)
SELECT
  sm_id,
  year,
  month_seq,
  SUM(total_sales)                     AS sum_sales,
  SUM(total_quantity)                  AS sum_quantity,
  AVG(avg_net_paid)                    AS avg_net_paid_per_order,
  rank() OVER (PARTITION BY year ORDER BY SUM(total_sales) DESC) AS sales_rank,
  (SELECT COUNT(*)
     FROM promotion p_sub
    WHERE p_sub.p_discount_active = 'Y'
      AND p_sub.p_cost > 100)       AS high_cost_active_promo_cnt
FROM joined_data
GROUP BY sm_id, year, month_seq
HAVING SUM(total_sales) > 5000
ORDER BY sum_sales DESC
LIMIT 100
