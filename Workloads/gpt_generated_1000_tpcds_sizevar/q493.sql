WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
order_diff AS (
    SELECT cs_order_number
    FROM sales_sample
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
),
joined_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cp.cp_department,
        d.d_year,
        ws.web_site_id,
        ws.web_state
    FROM sales_sample cs
    FULL OUTER JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = cs.cs_order_number
    WHERE
        d.d_year = 2001
        AND cp.cp_department IN ('Books', 'Electronics')
        AND ws.web_state = 'CA'
        AND cs.cs_net_profit > 0
        AND cs.cs_quantity >= 1
),
aggregated AS (
    SELECT
        cp_department,
        d_year,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_base
    GROUP BY cp_department, d_year
)
SELECT
    ROW_NUMBER() OVER (ORDER BY agg.total_profit DESC) AS row_num,
    agg.cp_department,
    agg.d_year,
    agg.total_profit,
    agg.total_quantity,
    agg.order_cnt,
    diff.order_missing_cnt
FROM aggregated agg
CROSS JOIN (
    SELECT COUNT(*) AS order_missing_cnt FROM order_diff
) diff
ORDER BY agg.total_profit DESC
LIMIT 100
