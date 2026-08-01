WITH combined_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        CASE WHEN cs.cs_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_category,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_quantity >= 2
      AND cs.cs_wholesale_cost > 10.00
      AND cs.cs_sales_price > 20.00
      AND i.i_class_id IN (5, 7, 9)
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 1
),
web_combined AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        CASE WHEN ws.ws_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_category,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity >= 2
      AND ws.ws_wholesale_cost > 10.00
      AND ws.ws_sales_price > 20.00
      AND i.i_class_id IN (5, 7, 9)
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 1
),
unioned_sales AS (
    SELECT * FROM combined_sales
    UNION ALL
    SELECT * FROM web_combined
),
agg_by_item AS (
    SELECT
        i_item_id,
        i_product_name,
        discount_category,
        SUM(ext_sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS transaction_count,
        AVG(quantity) AS avg_quantity
    FROM unioned_sales
    GROUP BY i_item_id, i_product_name, discount_category
    HAVING SUM(ext_sales_price) > 500
)
SELECT
    i_item_id,
    i_product_name,
    discount_category,
    total_sales,
    total_profit,
    transaction_count,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY discount_category ORDER BY total_sales DESC) AS sales_rank
FROM agg_by_item
WHERE total_sales > 1000
  AND total_profit > 100
  AND transaction_count >= 5
ORDER BY total_sales DESC
LIMIT 100
