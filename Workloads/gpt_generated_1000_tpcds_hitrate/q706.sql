WITH sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM
        store_sales
    GROUP BY
        ss_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    REGEXP_EXTRACT(s.s_store_name, '(\\w+)') AS first_word,
    CONCAT(s.s_store_name, ' - ', s.s_store_id) AS full_desc,
    CASE
        WHEN COALESCE(sa.total_net_profit, 0) > 10000 THEN 'High'
        WHEN COALESCE(sa.total_net_profit, 0) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    COALESCE(sa.total_net_profit, 0) AS total_net_profit,
    COALESCE(sa.sales_cnt, 0) AS sales_cnt,
    (
        SELECT
            SUM(sr_return_amt)
        FROM
            store_returns sr
        WHERE
            sr.sr_store_sk = s.s_store_sk
    ) AS total_return_amt
FROM
    store s
RIGHT OUTER JOIN sales_agg sa ON sa.ss_store_sk = s.s_store_sk
WHERE
    REGEXP_LIKE(s.s_store_name, 'Market')
    AND s.s_state LIKE 'C%'
ORDER BY
    total_net_profit DESC
