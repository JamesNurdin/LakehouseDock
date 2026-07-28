WITH base AS (
  SELECT
    d.d_year,
    s.s_state,
    i.i_category,
    cs.cs_net_paid_inc_ship_tax,
    ss.ss_net_paid_inc_tax,
    ws.ws_net_paid_inc_ship_tax,
    CASE
      WHEN cs.cs_net_paid_inc_ship_tax > 5000 THEN 'HIGH_CS'
      WHEN ss.ss_net_paid_inc_tax > 5000 THEN 'HIGH_SS'
      WHEN ws.ws_net_paid_inc_ship_tax > 5000 THEN 'HIGH_WS'
      ELSE 'LOW'
    END AS revenue_tier,
    r.r_reason_desc
  FROM
    date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT
  d_year,
  s_state,
  i_category,
  revenue_tier,
  COUNT(*) AS txn_count,
  SUM(cs_net_paid_inc_ship_tax) AS total_catalog_sales,
  SUM(ss_net_paid_inc_tax) AS total_store_sales,
  SUM(ws_net_paid_inc_ship_tax) AS total_web_sales,
  MIN(r_reason_desc) AS sample_reason
FROM base
WHERE
  d_year = 2001
  AND s_state = 'CA'
  AND i_category = 'Electronics'
GROUP BY ROLLUP (d_year, s_state, i_category, revenue_tier)
ORDER BY d_year DESC, s_state, i_category, revenue_tier
LIMIT 100
