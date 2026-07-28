WITH filtered_sales AS (
  SELECT cs.cs_ext_sales_price,
         cs.cs_net_profit,
         cs.cs_ext_discount_amt,
         i.i_category,
         i.i_class,
         i.i_size
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE cs.cs_ship_date_sk BETWEEN 2450830 AND 2450880
    AND cs.cs_wholesale_cost > 20
    AND cs.cs_coupon_amt < 2000
    AND i.i_manufact_id IN (212, 338, 460)
    AND i.i_size = 'large'
),
agg AS (
  SELECT i_category,
         i_class,
         i_size,
         SUM(cs_ext_sales_price) AS total_sales,
         SUM(cs_net_profit) AS total_profit,
         AVG(cs_ext_discount_amt) AS avg_discount,
         COUNT(*) AS order_cnt
  FROM filtered_sales
  GROUP BY ROLLUP (i_category, i_class, i_size)
)
SELECT i_category,
       i_class,
       i_size,
       total_sales,
       total_profit,
       avg_discount,
       order_cnt,
       CASE WHEN i_category IS NOT NULL AND i_class IS NOT NULL AND i_size IS NOT NULL
            THEN RANK() OVER (PARTITION BY i_class ORDER BY total_profit DESC)
            ELSE NULL
       END AS profit_rank_within_class
FROM agg
ORDER BY i_category, i_class, i_size
LIMIT 100
