WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_ext_list_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_ext_tax > 10.0
      AND ss.ss_ext_list_price BETWEEN 100.0 AND 5000.0
      AND ss.ss_quantity >= 2
),
agg_sales AS (
    SELECT
        fs.ss_item_sk,
        SUM(fs.ss_quantity) AS total_quantity,
        SUM(fs.ss_ext_sales_price) AS total_sales,
        SUM(fs.ss_ext_tax) AS total_tax,
        AVG(fs.ss_ext_sales_price) AS avg_price
    FROM filtered_sales fs
    GROUP BY fs.ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_color,
    i.i_size,
    i.i_brand,
    agg.total_quantity,
    agg.total_sales,
    agg.total_tax,
    agg.avg_price,
    RANK() OVER (ORDER BY agg.total_sales DESC) AS overall_sales_rank,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY agg.total_sales DESC) AS brand_sales_rank,
    SUM(agg.total_sales) OVER (PARTITION BY i.i_brand ORDER BY agg.total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS brand_cumulative_sales,
    (SELECT SUM(ss2.ss_ext_sales_price) FROM store_sales ss2 WHERE ss2.ss_item_sk = i.i_item_sk) AS overall_item_sales,
    CASE
        WHEN agg.total_sales > 20000 THEN 'High'
        WHEN agg.total_sales > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_tier,
    lateral_dates.high_quantity_days
FROM agg_sales agg
JOIN item i
    ON i.i_item_sk = agg.ss_item_sk
CROSS JOIN LATERAL (
    SELECT COUNT(DISTINCT ss3.ss_sold_date_sk) AS high_quantity_days
    FROM store_sales ss3
    WHERE ss3.ss_item_sk = i.i_item_sk
      AND ss3.ss_quantity > 5
) AS lateral_dates
WHERE i.i_color IN ('red', 'pink')
  AND i.i_size = 'extra large'
  AND i.i_rec_end_date >= DATE '2000-01-01'
  AND i.i_brand_id BETWEEN 1 AND 5
  AND i.i_category = 'Electronics'
  AND i.i_manufact_id IS NOT NULL
ORDER BY agg.total_sales DESC
LIMIT 100
