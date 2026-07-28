WITH returns_agg AS (
    SELECT
        wp.wp_url,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY wp.wp_url ORDER BY SUM(wr.wr_return_amt) DESC) AS rn_page
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)fault')
      AND wp.wp_url LIKE 'http%://%/electronics/%'
    GROUP BY GROUPING SETS ((wp.wp_url, r.r_reason_desc), (wp.wp_url), (r.r_reason_desc))
    HAVING SUM(wr.wr_return_amt) > 1000
),
sales_agg AS (
    SELECT
        wp.wp_url,
        CONCAT('All ', COALESCE(REGEXP_EXTRACT(wp.wp_url, '(?i)(electronics|sports|home)'), 'Pages')) AS r_reason_desc,
        SUM(ws.ws_net_profit) AS total_return_amt,
        COUNT(*) AS return_cnt,
        NULL AS rn_page
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE SUBSTRING(wp.wp_type, 1, 4) = 'Home'
      AND wp.wp_url LIKE '%sports%'
    GROUP BY wp.wp_url
),
combined AS (
    SELECT * FROM returns_agg
    UNION ALL
    SELECT * FROM sales_agg
)
SELECT
    c.wp_url,
    c.r_reason_desc,
    c.total_return_amt,
    c.return_cnt,
    c.rn_page,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        JOIN web_page wp2 ON wr2.wr_web_page_sk = wp2.wp_web_page_sk
        WHERE wp2.wp_url = c.wp_url
    ) AS page_return_total
FROM combined c
ORDER BY c.total_return_amt DESC
LIMIT 100
