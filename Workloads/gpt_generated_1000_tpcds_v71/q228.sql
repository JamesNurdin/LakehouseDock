WITH inv_agg AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_type,
    w.w_warehouse_name AS warehouse_name,
    cd.cd_gender AS customer_gender,
    cp.cp_department AS catalog_department,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_flag,
    RANK() OVER (PARTITION BY cc.cc_name ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank_by_cc,
    SUM(wr.wr_return_amt) AS total_return_amount,
    (SELECT AVG(cs2.cs_ext_discount_amt)
       FROM catalog_sales cs2
       WHERE cs2.cs_sold_date_sk BETWEEN 2451087 AND 2451543) AS avg_discount_all_sales
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN inv_agg i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_country = 'United States'
  AND sm.sm_type IN ('AIR', 'SEA')
  AND w.w_state = 'CA'
  AND cp.cp_department = 'Sports'
  AND cs.cs_sold_date_sk BETWEEN 2451087 AND 2451543
  AND cd.cd_gender = 'F'
GROUP BY
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    cd.cd_gender,
    cp.cp_department,
    i.inv_warehouse_sk
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
