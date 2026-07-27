WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        i.i_color,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_ext_tax,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_order_number
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    WHERE ss.ss_quantity BETWEEN 1 AND 5
      AND cs.cs_quantity > 2
      AND cs.cs_ext_discount_amt > 500
      AND cs.cs_ext_tax < 30
      AND i.i_color = 'Red'
)
SELECT
    cc.cc_name,
    cc.cc_manager,
    sm.sm_ship_mode_id,
    sm.sm_contract,
    isub.i_brand,
    isub.i_category,
    SUM(isub.cs_ext_sales_price) AS total_sales,
    AVG(isub.cs_ext_discount_amt) AS avg_discount,
    RANK() OVER (PARTITION BY cc.cc_manager ORDER BY SUM(isub.cs_ext_sales_price) DESC) AS sales_rank_per_manager,
    ROW_NUMBER() OVER (ORDER BY SUM(isub.cs_net_profit) DESC) AS overall_profit_rank,
    CASE
        WHEN SUM(isub.cs_ext_discount_amt) > (
            SELECT AVG(cs2.cs_ext_discount_amt)
            FROM catalog_sales cs2
            WHERE cs2.cs_ship_mode_sk = sm.sm_ship_mode_sk
        ) THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_category
FROM item_sales isub
JOIN call_center cc ON isub.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON isub.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cc.cc_company = 5
  AND sm.sm_code = 'AIR'
  AND cc.cc_manager = 'Jason Brito'
  AND sm.sm_contract = 'uukTktPYycct8'
GROUP BY
    cc.cc_name,
    cc.cc_manager,
    sm.sm_ship_mode_id,
    sm.sm_contract,
    isub.i_brand,
    isub.i_category,
    sm.sm_ship_mode_sk
ORDER BY total_sales DESC
LIMIT 100
