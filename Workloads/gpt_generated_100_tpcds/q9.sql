WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        i.i_category,
        cd.cd_gender,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_net_profit) AS total_profit,
        sum(ss.ss_quantity) AS total_quantity,
        sum(ss.ss_ext_discount_amt) AS total_discount_amount,
        sum(ss.ss_ext_sales_price) / nullif(sum(ss.ss_quantity), 0) AS avg_price_per_unit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy, i.i_category, cd.cd_gender
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_moy,
    i_category,
    cd_gender,
    total_sales,
    total_profit,
    total_quantity,
    (total_discount_amount / nullif(total_sales, 0)) * 100 AS discount_pct,
    avg_price_per_unit,
    rank() OVER (PARTITION BY d_year, d_moy ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
