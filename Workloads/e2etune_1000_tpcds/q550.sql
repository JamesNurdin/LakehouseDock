WITH filtered_sales AS (
    SELECT ss.*, i.i_brand, i.i_color, i.i_category, i.i_category_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_coupon_amt > 5
      AND ss.ss_ext_discount_amt > 0
      AND i.i_rec_start_date <= DATE '2000-01-01'
      AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= DATE '2000-01-01')
),
agg AS (
    SELECT i_brand,
           i_color,
           i_category,
           COUNT(*) AS sales_cnt,
           SUM(ss_net_profit) AS total_profit,
           AVG(ss_net_profit) AS avg_profit,
           SUM(ss_quantity) AS total_quantity,
           SUM(ss_ext_discount_amt) AS total_discount
    FROM filtered_sales
    GROUP BY i_brand, i_color, i_category
    HAVING COUNT(*) >= 50
)
SELECT i_brand,
       i_color,
       i_category,
       sales_cnt,
       total_profit,
       avg_profit,
       total_quantity,
       total_discount,
       (total_profit / NULLIF(total_quantity, 0)) AS profit_per_unit,
       ROW_NUMBER() OVER (ORDER BY avg_profit DESC) AS brand_color_rank
FROM agg
ORDER BY avg_profit DESC
LIMIT 10
