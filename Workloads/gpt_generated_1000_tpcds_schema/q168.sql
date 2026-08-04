WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity)       AS total_qty,
        COUNT(*)                  AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d              ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_page cp          ON d.d_date_sk = cp.cp_start_date_sk
    JOIN web_site w               ON d.d_date_sk = w.web_open_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND cd.cd_education_status = 'College'
      AND ss.ss_ext_sales_price > 1000
      AND d.d_weekend = 'N'
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    d_year,
    total_sales,
    total_qty,
    sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS rn_state,
    RANK()       OVER (ORDER BY total_sales DESC)          AS overall_rank
FROM sales_agg
ORDER BY overall_rank
LIMIT 100
