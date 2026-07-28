WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        i.i_brand,
        i.i_brand_id,
        i.i_item_desc,
        i.i_product_name,
        sm.sm_carrier,
        td.t_meal_time,
        td.t_shift
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
      AND sm.sm_carrier LIKE 'US%'
      AND td.t_meal_time = 'Lunch'
      AND td.t_shift LIKE 'A%'
)
SELECT
    sf.i_brand,
    sf.i_brand_id,
    sf.sm_carrier,
    CONCAT(sf.i_brand, ':', sf.i_item_desc) AS brand_item_desc,
    MIN(regexp_extract(sf.i_product_name, '^([^ ]+)', 1)) AS product_prefix,
    SUM(sf.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    COUNT(DISTINCT sf.cs_order_number) AS sales_orders,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders
FROM sales_filtered sf
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = sf.cs_order_number
   AND cr.cr_item_sk = sf.cs_item_sk
WHERE (cr.cr_reason_sk IS NULL OR regexp_like(CAST(cr.cr_reason_sk AS VARCHAR), '^[0-9]+$'))
GROUP BY sf.i_brand, sf.i_brand_id, sf.sm_carrier, sf.i_brand, sf.i_item_desc
ORDER BY total_net_profit DESC
LIMIT 20
