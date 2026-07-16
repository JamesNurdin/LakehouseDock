SELECT *
FROM (
    SELECT
        s_state,
        d_year,
        i_brand,
        total_sales,
        total_profit,
        txn_cnt,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM (
        SELECT
            s.s_state AS s_state,
            d.d_year AS d_year,
            i.i_brand AS i_brand,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit,
            COUNT(*) AS txn_cnt
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        WHERE d.d_year BETWEEN 1999 AND 2002
          AND i.i_category = 'Electronics'
          AND cd.cd_gender = 'M'
        GROUP BY s.s_state, d.d_year, i.i_brand
    ) agg
) ranked
WHERE sales_rank <= 10
ORDER BY d_year, sales_rank
