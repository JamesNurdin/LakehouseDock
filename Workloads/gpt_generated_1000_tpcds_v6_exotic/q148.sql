WITH sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_item_sk AS item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_current_week = 'N'
      AND d.d_following_holiday = 'N'
      AND i.i_category_id IN (2, 5)
      AND ss.ss_quantity > 0
      AND ss.ss_sales_price > 0
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_item_sk = ss.ss_item_sk
            AND wr.wr_returned_date_sk = ss.ss_sold_date_sk
      )
    GROUP BY GROUPING SETS (
        (d.d_year, i.i_category, i.i_brand, i.i_item_sk),
        (d.d_year, i.i_category, i.i_brand),
        (d.d_year, i.i_category),
        (d.d_year),
        ()
    )
),
returns_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(wr.wr_return_amt) AS total_returns,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_current_week = 'N'
      AND d.d_following_holiday = 'N'
      AND wr.wr_reversed_charge > 100
      AND wr.wr_account_credit < 50
      AND i.i_category_id IN (2, 5)
    GROUP BY ROLLUP (d.d_year, i.i_category)
)
SELECT
    s.d_year,
    s.i_category,
    s.i_brand,
    s.total_sales,
    s.total_profit,
    r.total_returns,
    r.total_loss,
    s.sales_cnt,
    r.returns_cnt,
    CASE
        WHEN s.total_sales = 0 THEN NULL
        ELSE ROUND(((s.total_sales - COALESCE(r.total_returns, 0)) / s.total_sales) * 100, 2)
    END AS sales_vs_returns_pct,
    ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank_year,
    RANK() OVER (ORDER BY (s.total_sales - COALESCE(r.total_returns, 0)) DESC) AS overall_sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.i_category = r.i_category
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr_chk
    WHERE wr_chk.wr_item_sk = s.item_sk
)
ORDER BY s.d_year, sales_rank_year
LIMIT 100
