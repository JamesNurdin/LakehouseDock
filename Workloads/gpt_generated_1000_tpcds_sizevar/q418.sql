WITH cr_base AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    cc.cc_call_center_id,
    cc.cc_class,
    cc.cc_county,
    cc.cc_city,
    cp.cp_department,
    sm.sm_ship_mode_id,
    sm.sm_code,
    w.w_warehouse_name,
    w.w_state,
    r.r_reason_desc,
    ca.ca_city,
    cd.cd_gender,
    split(cc.cc_city, ',') AS city_parts
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cc.cc_class = 'medium'
    AND cc.cc_county = 'Jackson County'
    AND cp.cp_department = 'Sports'
    AND sm.sm_code = 'AIR'
    AND w.w_state = 'CA'
    AND r.r_reason_desc LIKE '%defect%'
),
cr_unnested AS (
  SELECT
    crb.*,
    city_part
  FROM cr_base crb
  CROSS JOIN UNNEST(crb.city_parts) AS t(city_part)
),
wr_base AS (
  SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_net_loss,
    wr.wr_return_quantity,
    r.r_reason_desc AS wr_reason_desc,
    ca.ca_city,
    cd.cd_gender,
    split(ca.ca_city, ',') AS city_parts
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE r.r_reason_desc LIKE '%defect%'
    AND ca.ca_gmt_offset = -5.00
    AND cd.cd_gender = 'F'
    AND wr.wr_return_amt > 100
    AND wr.wr_return_quantity >= 1
    AND wr.wr_return_tax IS NOT NULL
),
wr_unnested AS (
  SELECT
    wrb.*,
    city_part
  FROM wr_base wrb
  CROSS JOIN UNNEST(wrb.city_parts) AS t(city_part)
),
intersect_keys AS (
  SELECT cr_order_number AS order_number FROM cr_base
  INTERSECT
  SELECT wr_order_number FROM wr_base
)
SELECT
  ik.order_number,
  SUM(cr_unnested.cr_return_amount) AS total_return_amount,
  AVG(wr_unnested.wr_return_amt) AS avg_web_return_amount,
  COUNT(DISTINCT cr_unnested.cc_call_center_id) AS distinct_call_centers,
  COUNT(*) FILTER (WHERE cr_unnested.city_part = 'New York') AS ny_city_parts
FROM intersect_keys ik
LEFT JOIN cr_unnested ON cr_unnested.cr_order_number = ik.order_number
LEFT JOIN wr_unnested ON wr_unnested.wr_order_number = ik.order_number
GROUP BY ik.order_number
HAVING SUM(cr_unnested.cr_return_amount) > 500
ORDER BY total_return_amount DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
