WITH
  returns_agg AS (
    SELECT sr_reason_sk,
           COUNT(*) AS ret_cnt,
           SUM(sr_net_loss) AS total_loss
    FROM store_returns
    GROUP BY sr_reason_sk
  ),
  sales_agg AS (
    SELECT cs_catalog_page_sk,
           SUM(cs_ext_sales_price) AS total_sales,
           SUM(cs_quantity) AS total_qty
    FROM catalog_sales
    GROUP BY cs_catalog_page_sk
  ),
  union_set AS (
    SELECT
      cp.cp_catalog_page_id,
      cp.cp_department,
      cp.cp_catalog_page_number,
      w.w_warehouse_name,
      w.w_state,
      ca.ca_state                     AS address_state,
      r.r_reason_desc,
      ra.ret_cnt,
      ra.total_loss,
      sa.total_sales,
      sa.total_qty,
      ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY sa.total_sales DESC) AS rn_state_sales,
      (SELECT COUNT(*) FROM store_returns sr_sub WHERE sr_sub.sr_reason_sk = r.r_reason_sk) AS reason_total_returns,
      EXISTS (
        SELECT 1
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_bill_customer_sk = cs.cs_bill_customer_sk
          AND cs_sub.cs_ext_sales_price > 5000
      ) AS has_big_bill_sales,
      FALSE AS has_big_ship_sales
    FROM catalog_page cp
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN returns_agg ra ON ra.sr_reason_sk = r.r_reason_sk
    LEFT JOIN sales_agg sa ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE w.w_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND ca.ca_country = 'United States'
      AND r.r_reason_desc LIKE '%defect%'
  ),
  union_set_ship AS (
    SELECT
      cp.cp_catalog_page_id,
      cp.cp_department,
      cp.cp_catalog_page_number,
      w.w_warehouse_name,
      w.w_state,
      ca2.ca_state                    AS address_state,
      r.r_reason_desc,
      ra.ret_cnt,
      ra.total_loss,
      sa.total_sales,
      sa.total_qty,
      ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY sa.total_sales DESC) AS rn_state_sales,
      (SELECT COUNT(*) FROM store_returns sr_sub WHERE sr_sub.sr_reason_sk = r.r_reason_sk) AS reason_total_returns,
      FALSE AS has_big_bill_sales,
      EXISTS (
        SELECT 1
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_ship_customer_sk = cs.cs_ship_customer_sk
          AND cs_sub.cs_ext_sales_price > 5000
      ) AS has_big_ship_sales
    FROM catalog_page cp
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca2 ON cs.cs_ship_addr_sk = ca2.ca_address_sk
    JOIN store_returns sr ON sr.sr_addr_sk = ca2.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN returns_agg ra ON ra.sr_reason_sk = r.r_reason_sk
    LEFT JOIN sales_agg sa ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE w.w_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND ca2.ca_country = 'United States'
      AND r.r_reason_desc LIKE '%defect%'
  ),
  combined AS (
    SELECT * FROM union_set
    UNION DISTINCT
    SELECT * FROM union_set_ship
  ),
  filtered AS (
    SELECT *
    FROM combined
    WHERE (has_big_bill_sales OR has_big_ship_sales)
      AND rn_state_sales <= 10
  ),
  final_set AS (
    SELECT *
    FROM filtered
    EXCEPT
    SELECT *
    FROM filtered
    WHERE cp_catalog_page_number < 5
  )
SELECT *
FROM final_set
ORDER BY w_state, rn_state_sales
LIMIT 100
