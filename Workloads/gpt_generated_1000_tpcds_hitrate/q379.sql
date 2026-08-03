WITH ws_arr AS (
    SELECT
        ws.*, 
        ARRAY[ws_ship_mode_sk, ws_warehouse_sk] AS sk_array
    FROM web_sales ws
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    CASE WHEN w.w_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag,
    COUNT(DISTINCT c.c_customer_sk)               AS unique_customers,
    SUM(ss.ss_net_paid)                           AS total_store_sales,
    SUM(ws_arr.ws_net_paid)                       AS total_web_sales,
    SUM(cr.cr_return_amount)                     AS total_return_amount,
    AVG(inv.inv_quantity_on_hand)                 AS avg_inventory,
    COUNT(t.sk)                                   AS total_sk_elements
FROM date_dim d
LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN ws_arr
    ON ws_arr.ws_sold_date_sk = d.d_date_sk
LEFT JOIN warehouse w
    ON ws_arr.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm
    ON ws_arr.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_site wsit
    ON ws_arr.ws_web_site_sk = wsit.web_site_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
-- Expand the array created in ws_arr
LEFT JOIN UNNEST(ws_arr.sk_array) AS t(sk) ON TRUE
WHERE d.d_year = 2001
  AND w.w_state = 'CA'
  AND c.c_birth_year = 1975
  AND cc.cc_name = 'Main Call Center'
  AND wsit.web_company_id = 3
  AND inv.inv_quantity_on_hand > 1000
GROUP BY
    d.d_year,
    w.w_warehouse_name,
    CASE WHEN w.w_state = 'CA' THEN 'West' ELSE 'Other' END
ORDER BY total_store_sales DESC
LIMIT 100
