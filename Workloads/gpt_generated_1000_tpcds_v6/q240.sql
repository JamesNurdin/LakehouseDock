WITH sales_item AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_manager_id,
        i.i_container,
        i.i_wholesale_cost,
        cc.cc_state,
        cc.cc_county,
        cc.cc_open_date_sk
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_county = 'Barrow County'
      AND i.i_manager_id = 34
      AND i.i_container = 'Unknown'
      AND i.i_wholesale_cost > 1.0
      AND cs.cs_quantity >= 5
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    si.cc_state,
    si.cc_county,
    si.i_manager_id,
    COUNT(*) AS order_count,
    SUM(si.cs_net_paid) AS total_net_paid,
    AVG(si.cs_net_profit) AS avg_net_profit,
    MIN(si.cs_net_paid) AS min_net_paid,
    MAX(si.cs_net_paid) AS max_net_paid
FROM sales_item si
WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = si.cs_catalog_page_sk
          AND cp.cp_department = 'Electronics'
    )
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs_neg
        WHERE cs_neg.cs_item_sk = si.cs_item_sk
          AND cs_neg.cs_net_profit < 0
    )
GROUP BY si.cc_state, si.cc_county, si.i_manager_id
ORDER BY total_net_paid DESC
LIMIT 100
