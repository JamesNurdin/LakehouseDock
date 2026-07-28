WITH sales_returns AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_country,
        ss.ss_cdemo_sk,
        cd.cd_credit_rating,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        SUM(CASE WHEN cr.cr_return_amount IS NOT NULL THEN 1 ELSE 0 END) AS return_cnt
    FROM
        store_sales ss
        INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
            AND cr.cr_return_amount > 0
    WHERE
        s.s_state = 'CA'
        AND s.s_country = 'United States'
        AND cd.cd_credit_rating = 'High Risk'
        AND ss.ss_net_paid_inc_tax > 500
        AND ss.ss_ext_tax BETWEEN 20 AND 200
        AND s.s_rec_start_date <= DATE '2005-12-31'
    GROUP BY
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_country,
        ss.ss_cdemo_sk,
        cd.cd_credit_rating
)
SELECT
    sr.s_store_name,
    sr.s_state,
    sr.s_country,
    sr.cd_credit_rating,
    sr.total_sales,
    sr.total_profit,
    sr.total_return_amount,
    sr.sales_cnt,
    sr.return_cnt,
    ROUND(sr.total_profit / NULLIF(sr.total_sales, 0), 4) AS profit_margin,
    RANK() OVER (ORDER BY sr.total_profit DESC) AS profit_rank
FROM
    sales_returns sr
WHERE
    sr.total_return_amount > 1000
    AND sr.return_cnt >= 1
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returning_cdemo_sk = sr.ss_cdemo_sk
          AND cr2.cr_return_amount > 500
    )
ORDER BY
    sr.total_profit DESC,
    sr.s_store_name
LIMIT 100
