WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT ss.*, i.i_category, i.i_color, d.d_month_seq
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)green')
      AND i.i_item_desc LIKE '%green%'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
)
SELECT
    i_category,
    d_month_seq,
    SUM(ss_net_paid) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    MAX(CASE WHEN i_color = 'Red' THEN 'R' ELSE i_color END) AS color_flag,
    (SELECT AVG(ss_net_profit) FROM store_sales) AS avg_profit_all,
    ROW_NUMBER() OVER (ORDER BY SUM(ss_net_profit) DESC) AS rn
FROM joined
GROUP BY CUBE (i_category, d_month_seq)
HAVING SUM(ss_net_paid) > 0
ORDER BY total_profit DESC
LIMIT 100
