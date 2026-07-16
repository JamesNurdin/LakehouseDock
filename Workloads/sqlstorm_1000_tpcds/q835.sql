WITH sales_by_cat AS (
    SELECT d.d_year,
           s.s_state,
           i.i_category,
           sum(ss.ss_net_paid) AS cat_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
    GROUP BY d.d_year, s.s_state, i.i_category
)
SELECT d_year,
       s_state,
       i_category,
       cat_sales
FROM (
    SELECT d_year,
           s_state,
           i_category,
           cat_sales,
           rank() OVER (PARTITION BY d_year, s_state ORDER BY cat_sales DESC) AS rnk
    FROM sales_by_cat
) t
WHERE rnk <= 5
ORDER BY d_year, s_state, cat_sales DESC
