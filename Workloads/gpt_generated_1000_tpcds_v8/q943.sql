WITH
    sampled_inventory AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_warehouse AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_warehouse_sk,
            cs.cs_item_sk,
            cs.cs_ext_sales_price,
            cs.cs_ship_hdemo_sk,
            w.w_warehouse_name,
            w.w_state,
            hd.hd_demo_sk,
            hd.hd_vehicle_count,
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM catalog_sales cs
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN household_demographics hd
            ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE cs.cs_ext_sales_price > 1000
          AND ib.ib_lower_bound >= 100001
          AND hd.hd_vehicle_count >= 0
    ),
    union_set AS (
        SELECT cs_sold_date_sk, cs_warehouse_sk, cs_ext_sales_price, cs_item_sk
        FROM sales_warehouse
        WHERE cs_ext_sales_price > 2000
        UNION
        SELECT cs_sold_date_sk, cs_warehouse_sk, cs_ext_sales_price, cs_item_sk
        FROM sales_warehouse
        WHERE cs_ext_sales_price BETWEEN 1500 AND 2000
    ),
    except_set AS (
        SELECT cs_warehouse_sk
        FROM sales_warehouse
        WHERE cs_ext_sales_price > 2500
        EXCEPT
        SELECT cs_warehouse_sk
        FROM sales_warehouse
        WHERE cs_ext_sales_price < 2000
    )
SELECT
    sw.cs_sold_date_sk,
    sw.cs_warehouse_sk,
    w.w_warehouse_name,
    sw.cs_item_sk,
    sw.cs_ext_sales_price,
    sw.cs_ext_sales_price * 0.1 AS ten_percent_of_sales,
    inv_latest.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY sw.cs_warehouse_sk ORDER BY sw.cs_ext_sales_price DESC) AS sales_rank,
    (SELECT AVG(cs2.cs_ext_sales_price)
       FROM catalog_sales cs2
       WHERE cs2.cs_warehouse_sk = sw.cs_warehouse_sk) AS avg_warehouse_sales,
    CASE
        WHEN sw.cs_ext_sales_price > 5000 THEN 'High'
        WHEN sw.cs_ext_sales_price > 3000 THEN 'Medium'
        ELSE 'Low'
    END AS price_category
FROM union_set us
JOIN sales_warehouse sw
    ON us.cs_sold_date_sk = sw.cs_sold_date_sk
   AND us.cs_warehouse_sk = sw.cs_warehouse_sk
   AND us.cs_ext_sales_price = sw.cs_ext_sales_price
   AND us.cs_item_sk = sw.cs_item_sk
JOIN warehouse w
    ON sw.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN LATERAL (
    SELECT inv.inv_quantity_on_hand
    FROM sampled_inventory inv
    WHERE inv.inv_item_sk = sw.cs_item_sk
      AND inv.inv_warehouse_sk = sw.cs_warehouse_sk
    ORDER BY inv.inv_date_sk DESC
    LIMIT 1
) inv_latest ON TRUE
WHERE EXISTS (
        SELECT 1
        FROM household_demographics hd2
        WHERE hd2.hd_demo_sk = sw.cs_ship_hdemo_sk
          AND hd2.hd_dep_count >= 5
      )
  AND sw.cs_warehouse_sk NOT IN (SELECT cs_warehouse_sk FROM except_set)
  AND (SELECT COUNT(*)
         FROM catalog_sales cs3
         WHERE cs3.cs_warehouse_sk = sw.cs_warehouse_sk
           AND cs3.cs_ext_sales_price > sw.cs_ext_sales_price) < 10
ORDER BY sw.cs_ext_sales_price DESC
LIMIT 100
