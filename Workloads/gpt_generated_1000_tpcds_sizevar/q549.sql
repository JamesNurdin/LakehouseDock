WITH base_join AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wp.wp_max_ad_count,
        l.qty_per_month
    FROM tpcds.date_dim AS d
    JOIN tpcds.store_sales AS ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns AS wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_page AS wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
    CROSS JOIN LATERAL (
        SELECT CAST(ss.ss_quantity AS double) / NULLIF(d.d_month_seq, 0) AS qty_per_month
    ) AS l
    WHERE d.d_fy_year = 1904                -- fiscal year filter
      AND d.d_qoy = 2                       -- quarter‑of‑year filter
      AND d.d_current_quarter = 'Y'         -- current quarter flag
      AND wp.wp_max_ad_count >= 1          -- page ad count filter
      AND ss.ss_ext_wholesale_cost > 500.00 -- wholesale cost filter
),
union_agg AS (
    SELECT
        d_year,
        d_quarter_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(wr_return_amt) AS total_returns,
        COUNT(DISTINCT ss_quantity) AS distinct_qty_sold,
        COUNT(DISTINCT wr_return_quantity) AS distinct_qty_returned
    FROM base_join
    WHERE wp_max_ad_count <= 3
      AND ss_net_profit > 0
    GROUP BY d_year, d_quarter_name

    UNION DISTINCT

    SELECT
        d_year,
        d_quarter_name,
        SUM(ss_ext_sales_price) * 0.9 AS total_sales,
        SUM(wr_return_amt) * 1.1 AS total_returns,
        COUNT(DISTINCT ss_quantity) AS distinct_qty_sold,
        COUNT(DISTINCT wr_return_quantity) AS distinct_qty_returned
    FROM base_join
    WHERE wp_max_ad_count >= 2
      AND ss_net_profit < 0
    GROUP BY d_year, d_quarter_name
)
SELECT
    d_year,
    d_quarter_name,
    SUM(total_sales) AS agg_total_sales,
    SUM(total_returns) AS agg_total_returns,
    COUNT(DISTINCT distinct_qty_sold) AS agg_distinct_qty_sold,
    COUNT(DISTINCT distinct_qty_returned) AS agg_distinct_qty_returned
FROM union_agg
GROUP BY d_year, d_quarter_name
ORDER BY agg_total_sales DESC
LIMIT 100
