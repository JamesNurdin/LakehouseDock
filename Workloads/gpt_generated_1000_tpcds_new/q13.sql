WITH sales AS (
   SELECT
      i.i_category AS category,
      COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
      SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE cs.cs_ship_mode_sk IN (2, 5, 7)
     AND cs.cs_list_price > 50
   GROUP BY i.i_category
),
returns AS (
   SELECT
      i.i_category AS category,
      COUNT(DISTINCT wr.wr_order_number) AS distinct_returns,
      SUM(DISTINCT wr.wr_return_amt) AS distinct_return_amt
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE wr.wr_fee > 20
   GROUP BY i.i_category
),
full_joined AS (
   SELECT
      COALESCE(s.category, r.category) AS category,
      s.distinct_orders,
      s.distinct_sales,
      r.distinct_returns,
      r.distinct_return_amt
   FROM sales s
   FULL OUTER JOIN returns r
     ON s.category = r.category
)
SELECT
   category,
   distinct_orders,
   distinct_sales,
   distinct_returns,
   distinct_return_amt
FROM full_joined
WHERE distinct_orders IS NOT NULL
UNION ALL
SELECT
   category,
   distinct_orders,
   distinct_sales,
   distinct_returns,
   distinct_return_amt
FROM full_joined
WHERE distinct_returns IS NOT NULL
ORDER BY category
LIMIT 100
