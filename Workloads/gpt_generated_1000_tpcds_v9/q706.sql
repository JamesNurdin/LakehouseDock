WITH sales_by_item_warehouse_demo AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk, cs.cs_bill_hdemo_sk
)
SELECT *
FROM (
    SELECT
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_id,
        'LowPotential' AS segment,
        sb.total_sales AS metric,
        (
            SELECT AVG(cs2.cs_wholesale_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_wholesale_cost
    FROM sales_by_item_warehouse_demo sb
    JOIN item i ON sb.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON sb.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON sb.hd_demo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND hd.hd_income_band_sk >= 10
      AND EXISTS (
          SELECT 1
          FROM warehouse w2
          WHERE w2.w_warehouse_sk = w.w_warehouse_sk
            AND w2.w_warehouse_sq_ft > 800000
      )

    UNION ALL

    SELECT
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_id,
        'HighPotential' AS segment,
        sb.total_profit AS metric,
        (
            SELECT AVG(cs2.cs_wholesale_cost)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_wholesale_cost
    FROM sales_by_item_warehouse_demo sb
    JOIN item i ON sb.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON sb.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON sb.hd_demo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential = '>10000'
      AND hd.hd_dep_count <= 2
) combined
ORDER BY segment, metric DESC
LIMIT 100
