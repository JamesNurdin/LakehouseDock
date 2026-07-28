WITH agg_a AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(cs.cs_ext_sales_price)          AS total_sales,
        AVG(cs.cs_ext_tax)                  AS avg_tax,
        COUNT(*)                            AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Riverside'
      AND w.w_zip = '42477'
      AND cs.cs_ext_wholesale_cost > 2000
      AND cs.cs_ext_list_price < 3000
    GROUP BY w.w_warehouse_id, w.w_city
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),
agg_b AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(cs.cs_ext_sales_price)          AS total_sales,
        AVG(cs.cs_ext_tax)                  AS avg_tax,
        COUNT(*)                            AS order_cnt
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Fairview'
      AND w.w_zip = '89275'
      AND cs.cs_ext_wholesale_cost BETWEEN 500 AND 1500
      AND cs.cs_ext_tax > 50
    GROUP BY w.w_warehouse_id, w.w_city
    HAVING COUNT(*) >= 5
)
SELECT
    comb.w_warehouse_id,
    comb.w_city,
    comb.total_sales,
    comb.avg_tax,
    comb.order_cnt,
    SUM(comb.total_sales) OVER (PARTITION BY comb.w_city) AS city_sales_total,
    RANK() OVER (ORDER BY comb.total_sales DESC)          AS sales_rank
FROM (
    SELECT w_warehouse_id, w_city, total_sales, avg_tax, order_cnt FROM agg_a
    UNION ALL
    SELECT w_warehouse_id, w_city, total_sales, avg_tax, order_cnt FROM agg_b
) AS comb
ORDER BY comb.total_sales DESC
LIMIT 20
