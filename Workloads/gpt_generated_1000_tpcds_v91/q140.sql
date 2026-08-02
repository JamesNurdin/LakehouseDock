SELECT
    i.i_brand,
    i.i_category,
    cp.cp_type,
    cc.cc_state,
    w.w_warehouse_name,
    t.t_hour,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COUNT(u.word) AS total_item_desc_word_cnt
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
LEFT JOIN call_center cc_ret
  ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
LEFT JOIN catalog_page cp_ret
  ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN time_dim t_ret
  ON cr.cr_returned_time_sk = t_ret.t_time_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_warehouse_sk = w.w_warehouse_sk
 AND ws.ws_sold_time_sk = t.t_time_sk
LEFT JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
LEFT JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS u(word)
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = cs.cs_order_number
)
GROUP BY
    i.i_brand,
    i.i_category,
    cp.cp_type,
    cc.cc_state,
    w.w_warehouse_name,
    t.t_hour
ORDER BY total_catalog_sales DESC
LIMIT 100
