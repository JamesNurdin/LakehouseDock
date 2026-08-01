WITH base AS (
  SELECT
    t.t_time_sk,
    t.t_hour,
    t.t_meal_time,
    ss.ss_sold_date_sk,
    ss.ss_addr_sk,
    ss.ss_quantity,
    ss.ss_net_profit,
    cs.cs_sold_date_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_item_sk,
    cs.cs_order_number,
    cr.cr_returned_date_sk,
    cr.cr_catalog_page_sk,
    cr.cr_ship_mode_sk,
    cr.cr_reason_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    wr.wr_returned_date_sk,
    wr.wr_reason_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    ws.ws_sold_date_sk,
    ws.ws_web_page_sk,
    ws.ws_ship_mode_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    cp.cp_department,
    cp.cp_type,
    cp.cp_description,
    sm_cat.sm_code AS sm_code_cat,
    sm_ws.sm_code AS sm_code_web,
    sm_cr.sm_code AS sm_code_return,
    r_cr.r_reason_desc AS reason_desc_cr,
    r_wr.r_reason_desc AS reason_desc_wr,
    wp.wp_type AS web_page_type_ws,
    wp_wr.wp_type AS web_page_type_wr,
    ca.ca_state,
    ca.ca_gmt_offset
  FROM time_dim t
  LEFT JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
  LEFT JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
  LEFT JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm_cat ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
  LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
  LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE cp.cp_department = 'DEPARTMENT'
    AND cp.cp_type = 'monthly'
    AND sm_cat.sm_code IN ('AIR','SEA')
    AND ss.ss_quantity > 2
    AND ws.ws_quantity > 1
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND ca.ca_gmt_offset < 0
),
expanded AS (
  SELECT
    base.*,
    word
  FROM base
  CROSS JOIN UNNEST(split(base.cp_description, ',')) AS t(word)
),
agg1 AS (
  SELECT
    cp_department,
    cp_type,
    sm_code_cat,
    t_hour,
    word,
    SUM(cs_net_profit) AS total_catalog_sales_profit,
    SUM(ss_net_profit) AS total_store_sales_profit,
    SUM(ws_net_profit) AS total_web_sales_profit,
    SUM(cr_net_loss) AS total_catalog_returns_loss,
    SUM(wr_net_loss) AS total_web_returns_loss,
    COUNT(*) AS txn_count
  FROM expanded
  GROUP BY GROUPING SETS (
    (cp_department, cp_type, sm_code_cat, t_hour, word),
    (cp_department, cp_type, sm_code_cat, t_hour),
    (cp_department, cp_type, sm_code_cat),
    (cp_department, cp_type),
    (cp_department),
    ()
  )
),
final AS (
  SELECT
    agg1.*,
    SUM(COALESCE(total_catalog_sales_profit,0) + COALESCE(total_store_sales_profit,0) + COALESCE(total_web_sales_profit,0))
        OVER (ORDER BY cp_department NULLS LAST, cp_type NULLS LAST) AS cumulative_profit,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY COALESCE(total_catalog_sales_profit,0) + COALESCE(total_store_sales_profit,0) + COALESCE(total_web_sales_profit,0) DESC) AS profit_rank
  FROM agg1
)
SELECT
  cp_department,
  cp_type,
  sm_code_cat,
  t_hour,
  word,
  total_catalog_sales_profit,
  total_store_sales_profit,
  total_web_sales_profit,
  total_catalog_returns_loss,
  total_web_returns_loss,
  txn_count,
  cumulative_profit,
  profit_rank
FROM final
ORDER BY cp_department, cp_type, sm_code_cat, t_hour, word
LIMIT 100
