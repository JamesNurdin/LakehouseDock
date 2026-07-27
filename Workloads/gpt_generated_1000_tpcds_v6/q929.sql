WITH filtered_sales AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand_id,
        w.w_warehouse_name,
        sm.sm_type,
        cd.cd_gender,
        concat(w.w_warehouse_name, ' - ', sm.sm_type) AS wh_ship_label,
        substring(i.i_product_name, 1, 10) AS prod_prefix,
        regexp_extract(i.i_product_name, '([0-9]{3})', 1) AS three_digit_code
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND i.i_product_name LIKE '%Ultra%'
      AND regexp_like(i.i_product_name, '[0-9]{3}')
      AND cs.cs_ext_sales_price > (
            SELECT avg(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
            WHERE i2.i_brand_id = i.i_brand_id
      )
)
SELECT 
    wh_ship_label,
    prod_prefix,
    three_digit_code,
    COUNT(DISTINCT order_number) AS orders_cnt,
    SUM(ext_sales_price) AS total_sales,
    AVG(net_profit) AS avg_profit
FROM (
    SELECT 
        cs_order_number AS order_number,
        cs_ext_sales_price AS ext_sales_price,
        cs_net_profit AS net_profit,
        wh_ship_label,
        prod_prefix,
        three_digit_code
    FROM filtered_sales
) agg
GROUP BY wh_ship_label, prod_prefix, three_digit_code
ORDER BY total_sales DESC
LIMIT 100
