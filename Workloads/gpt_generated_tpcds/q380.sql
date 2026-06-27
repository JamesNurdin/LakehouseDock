/*
  Analytical query: monthly sales performance by store and product category for 2001,
  limited to sales that occurred during an active promotion period.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_name AS s_store_name,
        d_sales.d_year AS d_year,
        d_sales.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_sales.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND d_sales.d_date BETWEEN d_start.d_date AND d_end.d_date
    GROUP BY s.s_store_name, d_sales.d_year, d_sales.d_month_seq, i.i_category
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    i_category,
    total_sales,
    total_discount,
    total_profit,
    total_quantity,
    distinct_items_sold,
    ROUND(total_discount / NULLIF(total_sales, 0) * 100, 2) AS discount_percent,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
