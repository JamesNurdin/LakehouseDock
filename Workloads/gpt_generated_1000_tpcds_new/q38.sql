WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_net_profit) AS avg_profit
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
      AND ss_quantity >= 1
      AND ss_ext_discount_amt < 5000
      AND ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ss_item_sk, ss_hdemo_sk
)
SELECT
    i.i_brand,
    i.i_category,
    hd.hd_buy_potential,
    CASE
        WHEN sales_agg.avg_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_category,
    SUM(sales_agg.total_sales) AS brand_category_sales,
    AVG(sales_agg.total_quantity) AS avg_quantity_per_hdemo
FROM sales_agg
JOIN item i
    ON sales_agg.ss_item_sk = i.i_item_sk
JOIN household_demographics hd
    ON sales_agg.ss_hdemo_sk = hd.hd_demo_sk
WHERE i.i_wholesale_cost > 1.00
  AND i.i_color IN ('smoke', 'lime')
  AND hd.hd_vehicle_count >= 2
  AND hd.hd_dep_count <= 5
GROUP BY i.i_brand,
         i.i_category,
         hd.hd_buy_potential,
         CASE
            WHEN sales_agg.avg_profit > 0 THEN 'Profitable'
            ELSE 'Loss'
         END
ORDER BY brand_category_sales DESC
LIMIT 100
