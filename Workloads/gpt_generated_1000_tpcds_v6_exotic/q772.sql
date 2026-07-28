WITH store_daily AS (
    SELECT
        d.d_date AS sale_date,
        'store' AS source,
        SUM(ss.ss_net_paid) AS net_amount,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'profitable' ELSE 'not_profitable' END AS profitability
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
),
web_daily AS (
    SELECT
        d.d_date AS sale_date,
        'web' AS source,
        SUM(wr.wr_net_loss) AS net_amount,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'high_return' ELSE 'low_return' END AS return_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc <> 'Lost my job'
      AND d.d_year = 2001
    GROUP BY d.d_date
)
SELECT
    combined.sale_date,
    combined.source,
    combined.net_amount,
    combined.category
FROM (
    SELECT sale_date, source, net_amount, profitability AS category
    FROM store_daily
    UNION ALL
    SELECT sale_date, source, net_amount, return_category AS category
    FROM web_daily
) combined
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    JOIN reason r2 ON wr2.wr_reason_sk = r2.r_reason_sk
    JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
    WHERE r2.r_reason_desc = 'Lost my job'
      AND d2.d_date = combined.sale_date
)
ORDER BY combined.sale_date DESC, combined.source
LIMIT 100
