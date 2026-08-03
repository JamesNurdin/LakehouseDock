WITH base_agg AS (
    SELECT
        r.r_reason_desc,
        cc.cc_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(sr.sr_return_ship_cost) AS total_ship_cost,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'TX'
      AND cc.cc_employees > 200
      AND cp.cp_department = 'Books'
      AND cr.cr_returned_time_sk BETWEEN 10000 AND 40000
      AND sr.sr_return_ship_cost > 100
      AND cr.cr_return_amount > 0
      AND cs.cs_quantity > 1
    GROUP BY r.r_reason_desc, cc.cc_name
)
,
unioned AS (
    SELECT
        r_reason_desc,
        cc_name,
        total_return_amount,
        total_net_profit,
        total_ship_cost,
        order_cnt,
        AVG(total_return_amount) OVER (PARTITION BY r_reason_desc) AS avg_return_amount_by_reason,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY total_return_amount DESC) AS rank_by_return
    FROM base_agg
    WHERE total_net_profit > 5000
    
    UNION DISTINCT
    
    SELECT
        r_reason_desc,
        cc_name,
        total_return_amount,
        total_net_profit,
        total_ship_cost,
        order_cnt,
        AVG(total_return_amount) OVER (PARTITION BY r_reason_desc) AS avg_return_amount_by_reason,
        ROW_NUMBER() OVER (PARTITION BY r_reason_desc ORDER BY total_return_amount DESC) AS rank_by_return
    FROM base_agg
    WHERE total_ship_cost > 1000
)
SELECT *
FROM unioned
ORDER BY total_return_amount DESC
OFFSET 0
LIMIT 100
