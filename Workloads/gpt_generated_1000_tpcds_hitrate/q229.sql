WITH cs AS (
    SELECT *
    FROM catalog_sales
    WHERE cs_quantity > 0
)
SELECT
    cs.cs_order_number,
    d.d_year,
    cp.cp_catalog_number,
    sm.sm_type,
    w.w_warehouse_name,
    CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    cs.cs_ext_sales_price,
    avg_page_price.avg_price,
    RANK() OVER (PARTITION BY d.d_year ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank,
    ws.ws_order_number AS web_order,
    url_seg.segment
FROM cs
LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
RIGHT OUTER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN LATERAL (
    SELECT AVG(cs2.cs_ext_sales_price) AS avg_price
    FROM catalog_sales cs2
    WHERE cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
) avg_page_price ON TRUE
LEFT JOIN UNNEST(split(wp.wp_url, '/')) AS url_seg(segment) ON TRUE
WHERE d.d_year = 2001
  AND cp.cp_catalog_number IN (3, 11)
  AND sm.sm_type = 'AIR'
  AND ib.ib_lower_bound >= 30000
  AND cc.cc_gmt_offset BETWEEN -5 AND 5
ORDER BY d.d_year, sales_rank
LIMIT 100
