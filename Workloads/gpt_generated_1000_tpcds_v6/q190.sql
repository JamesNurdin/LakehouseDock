WITH filtered_sales AS (
    SELECT
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cs.cs_ext_ship_cost,
        cc.cc_name,
        cc.cc_class,
        cc.cc_company,
        cc.cc_hours,
        i.i_brand,
        i.i_category,
        i.i_container,
        i.i_formulation
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_class = 'large'
      AND cc.cc_company = 5
      AND cc.cc_hours = '8AM-12AM'
      AND cs.cs_ext_ship_cost > 500
      AND cs.cs_quantity BETWEEN 2 AND 10
      AND i.i_container = 'Unknown'
      AND i.i_formulation LIKE '%goldenrod%'
      AND cs.cs_sold_date_sk IN (
          SELECT DISTINCT cs2.cs_sold_date_sk
          FROM catalog_sales cs2
          WHERE cs2.cs_ext_discount_amt > 100
      )
)
SELECT
    cc_name,
    i_brand,
    i_category,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    MIN(cs_ext_ship_cost) AS min_ship_cost,
    MAX(cs_ext_ship_cost) AS max_ship_cost
FROM filtered_sales
GROUP BY cc_name, i_brand, i_category
ORDER BY total_sales DESC
LIMIT 100
