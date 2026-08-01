WITH sampled_warehouse AS (
    SELECT *
    FROM warehouse
    TABLESAMPLE BERNOULLI (10)
),
distinct_cities AS (
    SELECT DISTINCT w_city
    FROM sampled_warehouse
)

SELECT
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_city,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_amount,
    AVG(cr.cr_return_tax) AS avg_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_return_quantity) AS min_qty,
    MAX(cr.cr_return_quantity) AS max_qty
FROM catalog_returns cr
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN sampled_warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN distinct_cities dc ON w.w_city = dc.w_city
WHERE cc.cc_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'TX'
  AND web.web_mkt_id = 3
  AND cr.cr_return_amount > 500
  AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_reason_sk = r.r_reason_sk
          AND sr2.sr_net_loss > 1000
    )
GROUP BY cc.cc_name, cp.cp_department, sm.sm_type, w.w_city, r.r_reason_desc
HAVING SUM(cr.cr_return_amount) > 1000

UNION

SELECT
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_city,
    r.r_reason_desc,
    SUM(ws.ws_net_paid) AS total_amount,
    AVG(ws.ws_ext_tax) AS avg_tax,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_quantity) AS min_qty,
    MAX(ws.ws_quantity) AS max_qty
FROM store_returns sr
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN sampled_warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN distinct_cities dc ON w.w_city = dc.w_city
WHERE cc.cc_state = 'NY'
  AND cp.cp_department = 'Books'
  AND sm.sm_type = 'GROUND'
  AND w.w_state = 'FL'
  AND web.web_mkt_id = 5
  AND ws.ws_quantity > 2
  AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = r.r_reason_sk
          AND cr2.cr_return_amount > 2000
    )
GROUP BY cc.cc_name, cp.cp_department, sm.sm_type, w.w_city, r.r_reason_desc
HAVING SUM(ws.ws_net_paid) > 2000

ORDER BY total_amount DESC
LIMIT 100
