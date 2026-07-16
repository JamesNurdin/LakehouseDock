SELECT *
FROM (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (
            PARTITION BY s.s_store_name, d.d_year
            ORDER BY SUM(ss.ss_net_profit) DESC
        ) AS category_rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_category
) t
WHERE t.category_rank <= 5
ORDER BY t.s_store_name, t.d_year, t.category_rank
