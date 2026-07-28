WITH base AS (
  SELECT
    s.s_store_id,
    s.s_state,
    r.r_reason_desc,
    cs.cs_net_profit,
    cs.cs_order_number,
    cr.cr_return_amount,
    d.d_year,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    cc.cc_state,
    ca.ca_state,
    w.w_warehouse_name,
    cp.cp_catalog_page_id,
    ws.web_name,
    inv.inv_quantity_on_hand
  FROM date_dim d
  -- Fact tables
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  -- Dimension tables linked via the allowed rules
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
),
agg AS (
  SELECT
    s_store_id,
    r_reason_desc,
    SUM(cs_net_profit) - SUM(cr_return_amount) AS net_gain
  FROM base
  WHERE d_year = 2001
    AND cd_gender = 'M'
    AND cd_purchase_estimate > 3000
    AND cc_state = 'CA'
  GROUP BY s_store_id, r_reason_desc
),
avg_gain AS (
  SELECT AVG(net_gain) AS avg_net_gain FROM agg
)
SELECT
  a.s_store_id,
  a.r_reason_desc,
  a.net_gain,
  g.avg_net_gain
FROM agg a
CROSS JOIN avg_gain g
ORDER BY a.net_gain DESC
LIMIT 50
