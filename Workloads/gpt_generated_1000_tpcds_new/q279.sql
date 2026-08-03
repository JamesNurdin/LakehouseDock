WITH avg_gmt_offset AS (
    SELECT AVG(cc_gmt_offset) AS avg_offset
    FROM call_center
)
SELECT
    sm.sm_type,
    dd.d_year,
    dd.d_month_seq,
    concat(ws.web_name, ' - ', sm.sm_type) AS site_ship_desc,
    SUM(cs.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
FROM catalog_sales cs
JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
WHERE cc.cc_gmt_offset > (SELECT avg_offset FROM avg_gmt_offset)
  AND regexp_like(sm.sm_contract, '^[A-Z0-9]{5,}$')
  AND ws.web_name LIKE '%Online%'
GROUP BY
    sm.sm_type,
    dd.d_year,
    dd.d_month_seq,
    concat(ws.web_name, ' - ', sm.sm_type)
ORDER BY total_net_paid DESC
LIMIT 100
