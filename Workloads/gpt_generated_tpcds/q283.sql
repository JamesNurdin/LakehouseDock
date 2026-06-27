WITH sales_agg AS (
    SELECT
        s.s_store_id,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')) AS year_month,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        s.s_store_id,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')),
        i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_id,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')) AS year_month,
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY
        s.s_store_id,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')),
        i.i_category,
        r.r_reason_desc
),
top_reason AS (
    SELECT
        store_id,
        year_month,
        category,
        r_reason_desc,
        total_return_amt,
        return_cnt,
        ROW_NUMBER() OVER (PARTITION BY store_id, year_month, category ORDER BY return_cnt DESC) AS rn
    FROM (
        SELECT
            s.s_store_id AS store_id,
            concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')) AS year_month,
            i.i_category AS category,
            r.r_reason_desc,
            SUM(sr.sr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d
            ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        GROUP BY
            s.s_store_id,
            concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')),
            i.i_category,
            r.r_reason_desc
    ) sub
)
SELECT
    sa.s_store_id,
    sa.year_month,
    sa.i_category,
    sa.total_sales,
    sa.total_profit,
    COALESCE(ra.total_return_amt, 0) AS total_return_amt,
    CASE
        WHEN sa.total_sales > 0 THEN COALESCE(ra.total_return_amt, 0) / sa.total_sales
        ELSE 0
    END AS return_rate,
    tr.r_reason_desc AS top_return_reason,
    tr.return_cnt AS top_reason_count
FROM sales_agg sa
LEFT JOIN (
    SELECT
        s_store_id,
        year_month,
        i_category,
        SUM(total_return_amt) AS total_return_amt
    FROM returns_agg
    GROUP BY
        s_store_id,
        year_month,
        i_category
) ra
    ON sa.s_store_id = ra.s_store_id
   AND sa.year_month = ra.year_month
   AND sa.i_category = ra.i_category
LEFT JOIN top_reason tr
    ON sa.s_store_id = tr.store_id
   AND sa.year_month = tr.year_month
   AND sa.i_category = tr.category
   AND tr.rn = 1
ORDER BY sa.total_profit DESC
LIMIT 100
