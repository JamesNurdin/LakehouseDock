WITH sales_agg AS (
  SELECT
    i.i_item_id,
    i.i_category,
    cc.cc_name AS call_center_name,
    cp.cp_type,
    w.w_warehouse_name,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    CASE
      WHEN SUM(cs.cs_ext_sales_price) > 0 THEN SUM(ss.ss_ext_sales_price) / SUM(cs.cs_ext_sales_price)
      ELSE NULL
    END AS store_to_catalog_ratio,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender
  FROM catalog_sales cs
  JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_time_sk = td_cs.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE td_cs.t_hour BETWEEN 8 AND 12
    AND i.i_current_price BETWEEN 5 AND 20
    AND cc.cc_state = 'CA'
  GROUP BY i.i_item_id, i.i_category, cc.cc_name, cp.cp_type, w.w_warehouse_name, cd_bill.cd_gender, cd_ship.cd_gender
),
returns_agg AS (
  SELECT
    i.i_item_id,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level
  FROM store_returns sr
  JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE td_sr.t_hour IN (9, 10, 11)
    AND r.r_reason_desc LIKE '%price%'
    AND s.s_state = 'CA'
  GROUP BY i.i_item_id
),
combined AS (
  SELECT
    sa.i_item_id,
    sa.i_category,
    sa.call_center_name,
    sa.cp_type,
    sa.w_warehouse_name,
    sa.catalog_sales_total,
    sa.store_sales_total,
    ra.total_return_amount,
    ra.return_cnt,
    sa.store_to_catalog_ratio,
    ra.return_level
  FROM sales_agg sa
  LEFT JOIN returns_agg ra ON sa.i_item_id = ra.i_item_id
)
SELECT
  c.i_item_id,
  c.i_category,
  c.call_center_name,
  c.cp_type,
  c.w_warehouse_name,
  c.catalog_sales_total,
  c.store_sales_total,
  c.total_return_amount,
  c.return_cnt,
  c.store_to_catalog_ratio,
  c.return_level,
  (SELECT AVG(store_to_catalog_ratio) FROM combined) AS overall_avg_ratio
FROM combined c
WHERE c.store_to_catalog_ratio > 0.5
  AND (c.total_return_amount IS NULL OR c.total_return_amount < 500)
  AND c.i_item_id IN (
        SELECT i_item_id FROM returns_agg WHERE return_level = 'HIGH'
        EXCEPT
        SELECT i_item_id FROM sales_agg WHERE store_sales_total = 0
      )
ORDER BY c.catalog_sales_total DESC, c.store_sales_total DESC
LIMIT 100
