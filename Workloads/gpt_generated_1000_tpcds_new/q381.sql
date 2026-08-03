WITH sales_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        (
            SELECT SUM(cr.cr_return_amount)
            FROM catalog_returns cr
            JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
            WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
              AND dr.d_year = d.d_year
              AND dr.d_month_seq = d.d_month_seq
        ) AS total_returns_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY w.w_warehouse_id, w.w_warehouse_sk, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY w.w_warehouse_id, w.w_warehouse_sk, d.d_year, d.d_month_seq
),
common_keys AS (
    SELECT w_warehouse_id, d_year, d_month_seq
    FROM sales_agg
    INTERSECT
    SELECT w_warehouse_id, d_year, d_month_seq
    FROM returns_agg
),
combined AS (
    SELECT
        s.w_warehouse_id,
        s.d_year,
        s.d_month_seq,
        s.total_sales,
        s.total_profit,
        s.profit_category,
        s.total_returns_amount,
        r.total_returns,
        r.return_cnt
    FROM sales_agg s
    JOIN returns_agg r
        ON s.w_warehouse_id = r.w_warehouse_id
       AND s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
    JOIN common_keys ck
        ON s.w_warehouse_id = ck.w_warehouse_id
       AND s.d_year = ck.d_year
       AND s.d_month_seq = ck.d_month_seq
),
overall AS (
    SELECT
        'ALL' AS w_warehouse_id,
        d_year,
        d_month_seq,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit,
        CASE WHEN SUM(total_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        SUM(total_returns_amount) AS total_returns_amount,
        SUM(total_returns) AS total_returns,
        SUM(return_cnt) AS return_cnt
    FROM combined
    GROUP BY d_year, d_month_seq
),
unioned AS (
    SELECT * FROM combined
    UNION ALL
    SELECT * FROM overall
),
aggregated_rollup AS (
    SELECT
        w_warehouse_id,
        d_year,
        d_month_seq,
        SUM(total_sales) AS total_sales,
        SUM(total_profit) AS total_profit,
        CASE WHEN SUM(total_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        SUM(total_returns_amount) AS total_returns_amount,
        SUM(total_returns) AS total_returns,
        SUM(return_cnt) AS return_cnt
    FROM unioned
    GROUP BY ROLLUP (w_warehouse_id, d_year, d_month_seq)
)
SELECT
    w_warehouse_id,
    d_year,
    d_month_seq,
    total_sales,
    total_profit,
    profit_category,
    total_returns_amount,
    total_returns,
    return_cnt
FROM (
    SELECT
        w_warehouse_id,
        d_year,
        d_month_seq,
        total_sales,
        total_profit,
        profit_category,
        total_returns_amount,
        total_returns,
        return_cnt,
        ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_sales DESC) AS rn
    FROM aggregated_rollup
) t
WHERE rn <= 5 OR w_warehouse_id IS NULL
ORDER BY w_warehouse_id NULLS FIRST, d_year, d_month_seq
LIMIT 100
