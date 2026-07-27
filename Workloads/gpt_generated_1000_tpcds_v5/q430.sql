WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_division,
        cc.cc_market_manager,
        sm.sm_ship_mode_id,
        sm.sm_type,
        i.i_item_id,
        i.i_brand_id,
        i.i_category,
        i.i_current_price
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_list_price > 100
      AND cs.cs_ext_sales_price BETWEEN 500 AND 5000
      AND i.i_brand_id IN (3002001, 10008011)
      AND cc.cc_division = 3
      AND cc.cc_market_manager = 'Kim Wilson'
      AND sm.sm_type = 'AIR'
)
SELECT DISTINCT
    fs.cc_call_center_id,
    fs.cc_name,
    fs.i_item_id,
    fs.i_brand_id,
    fs.sm_ship_mode_id,
    fs.sm_type,
    fs.cs_ext_sales_price,
    fs.cs_net_profit,
    avg_item_price,
    ROW_NUMBER() OVER (PARTITION BY fs.cc_call_center_id ORDER BY fs.cs_ext_sales_price DESC) AS sales_rank,
    CASE
        WHEN fs.cs_net_profit > 0 THEN 'PROFITABLE'
        ELSE 'LOSS'
    END AS profit_flag
FROM (
    SELECT
        fs.*,
        (SELECT AVG(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_item_sk = fs.cs_item_sk) AS avg_item_price
    FROM filtered_sales fs
) fs
ORDER BY fs.cc_call_center_id, sales_rank
LIMIT 100
