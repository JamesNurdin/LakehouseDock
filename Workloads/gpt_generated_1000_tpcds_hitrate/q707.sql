WITH catalog_agg AS (
  SELECT
    cs.cs_call_center_sk,
    cs.cs_warehouse_sk,
    cr.cr_reason_sk,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
  FROM tpcds.catalog_sales cs
  JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN tpcds.catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cc.cc_tax_percentage > 0.05
    AND w.w_gmt_offset BETWEEN -5 AND 5
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    AND cs.cs_quantity > 0
    AND cs.cs_sales_price > 10
    AND cs.cs_list_price < 300
  GROUP BY cs.cs_call_center_sk, cs.cs_warehouse_sk, cr.cr_reason_sk
),

web_agg AS (
  SELECT
    ws.ws_warehouse_sk,
    wr.wr_reason_sk,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(ws.ws_net_paid) > 8000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
  FROM tpcds.web_sales ws
  JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN tpcds.web_returns wr ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE w.w_gmt_offset BETWEEN -5 AND 5
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    AND ws.ws_quantity > 0
    AND ws.ws_sales_price > 5
    AND ws.ws_list_price BETWEEN 20 AND 300
    AND ws.ws_ship_mode_sk IS NOT NULL
  GROUP BY ws.ws_warehouse_sk, wr.wr_reason_sk
),

combined AS (
  SELECT
    ca.cs_call_center_sk AS dim_key,
    ca.cs_warehouse_sk AS warehouse_key,
    ca.cr_reason_sk AS reason_key,
    ca.total_net_paid,
    ca.total_discount,
    ca.order_cnt,
    ca.revenue_category
  FROM catalog_agg ca
  UNION
  SELECT
    NULL AS dim_key,
    wa.ws_warehouse_sk AS warehouse_key,
    wa.wr_reason_sk AS reason_key,
    wa.total_net_paid,
    wa.total_discount,
    wa.order_cnt,
    wa.revenue_category
  FROM web_agg wa
)

SELECT
  c.dim_key,
  c.warehouse_key,
  c.reason_key,
  c.revenue_category,
  c.total_net_paid,
  c.total_discount,
  c.order_cnt,
  (
    SELECT AVG(total_net_paid)
    FROM combined sub
    WHERE sub.warehouse_key = c.warehouse_key
  ) AS avg_warehouse_net_paid
FROM combined c
WHERE c.total_net_paid > 5000
  AND c.total_discount > 100
  AND c.order_cnt >= 10
  AND (c.reason_key IS NOT NULL OR c.dim_key IS NOT NULL)
  AND c.revenue_category = 'HIGH'
  AND c.warehouse_key IS NOT NULL
ORDER BY c.total_net_paid DESC
LIMIT 100
