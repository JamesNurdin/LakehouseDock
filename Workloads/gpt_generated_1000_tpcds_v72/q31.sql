WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_manager_id,
        cp.cp_department,
        sm.sm_carrier,
        sm.sm_code,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ship_date_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_sold_date_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_manager_id IN (64, 4, 25)
      AND i.i_container = 'Unknown'
      AND sm.sm_carrier = 'DHL'
      AND sm.sm_code = 'AIR'
      AND cp.cp_department = 'DEPARTMENT'
      AND cp.cp_end_date_sk BETWEEN 2451084 AND 2451270
      AND cs.cs_quantity > 5
      AND ss.ss_quantity > 2
      AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
              AND inv.inv_quantity_on_hand > 0
        )
)
SELECT
    i_item_id,
    i_product_name,
    i_manager_id,
    cp_department,
    sm_carrier,
    sm_code,
    COUNT(DISTINCT cs_order_number)               AS orders_cnt,
    SUM(cs_ext_sales_price) + SUM(ss_ext_sales_price) AS total_sales,
    AVG(cs_net_profit)                            AS avg_profit,
    MIN(cs_ship_date_sk)                          AS first_ship_date_sk,
    MAX(ss_sold_date_sk)                          AS last_sold_date_sk
FROM item_sales
GROUP BY
    i_item_id,
    i_product_name,
    i_manager_id,
    cp_department,
    sm_carrier,
    sm_code
HAVING (SUM(cs_ext_sales_price) + SUM(ss_ext_sales_price)) > 1000
ORDER BY total_sales DESC
LIMIT 100
