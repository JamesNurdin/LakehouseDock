WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        w.w_warehouse_sk,
        w.w_state,
        w.w_city,
        cp.cp_description,
        cc.cc_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND regexp_like(i.i_product_name, '(?i)premium')
      AND cp.cp_description LIKE '%holiday%'
)
SELECT
    sd.w_state,
    CONCAT(sd.w_city, ', ', sd.w_state) AS location,
    COUNT(DISTINCT sd.i_item_sk) AS distinct_items_sold,
    SUM(sd.cs_quantity) AS total_quantity,
    SUM(sd.cs_net_paid) AS total_net_paid,
    SUM(sd.cs_net_profit) AS total_profit,
    CASE
        WHEN SUM(sd.cs_net_profit) > 100000 THEN 'High'
        WHEN SUM(sd.cs_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_data sd
WHERE sd.i_category IN (
    SELECT i2.i_category
    FROM item i2
    WHERE i2.i_current_price > 200
      AND regexp_extract(i2.i_product_name, '^([A-Z]{2})') = 'AB'
)
GROUP BY sd.w_state, sd.w_city
ORDER BY total_profit DESC
LIMIT 100
