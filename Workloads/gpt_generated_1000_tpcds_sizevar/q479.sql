WITH returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        MAX(r.r_reason_desc) AS sample_reason_desc
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY wr.wr_order_number
)

SELECT
    cc.cc_call_center_id AS call_center_id,
    i.i_item_id AS item_id,
    cs.cs_quantity AS quantity_sold,
    cs.cs_net_profit AS net_profit,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    SUM(cs.cs_net_paid) OVER (
        PARTITION BY cc.cc_call_center_id 
        ORDER BY cs.cs_order_number 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_net_paid,
    ra.total_return_amt,
    ws.ws_quantity AS web_quantity,
    we.web_name AS web_site_name
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w1 ON cs.cs_warehouse_sk = w1.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    AND ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN returns_agg ra ON cs.cs_order_number = ra.wr_order_number
WHERE cc.cc_country = 'United States'
  AND cc.cc_division IN (1, 2, 3)
  AND i.i_brand = 'BrandX'
  AND sm_cs.sm_contract = '5FKNB0j8aaqTB'
  AND w1.w_state = 'CA'
  AND we.web_country = 'United States'

UNION DISTINCT

SELECT
    cc.cc_call_center_id,
    i.i_item_id,
    cs.cs_quantity,
    cs.cs_net_profit,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cs.cs_net_profit DESC),
    SUM(cs.cs_net_paid) OVER (
        PARTITION BY cc.cc_call_center_id 
        ORDER BY cs.cs_order_number 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ),
    ra.total_return_amt,
    ws.ws_quantity,
    we.web_name
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w1 ON cs.cs_warehouse_sk = w1.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    AND ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
LEFT JOIN returns_agg ra ON cs.cs_order_number = ra.wr_order_number
WHERE cc.cc_country = 'United States'
  AND cc.cc_division = 4
  AND i.i_brand = 'BrandY'
  AND sm_cs.sm_contract = 'YvxVaJI10'
  AND w1.w_state = 'TX'
  AND we.web_country = 'United States'

LIMIT 100
