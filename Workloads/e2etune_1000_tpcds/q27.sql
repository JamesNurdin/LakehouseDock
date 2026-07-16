WITH sales AS (
    SELECT
        s.s_state AS state,
        cd.cd_credit_rating AS credit_rating,
        cd.cd_gender AS gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IN ('Good', 'High Risk')
    GROUP BY s.s_state, cd.cd_credit_rating, cd.cd_gender
),
returns AS (
    SELECT
        cd.cd_credit_rating AS credit_rating,
        cd.cd_gender AS gender,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IN ('Good', 'High Risk')
    GROUP BY cd.cd_credit_rating, cd.cd_gender
)
SELECT
    s.state,
    s.credit_rating,
    s.gender,
    s.total_net_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    (s.total_net_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY s.credit_rating ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank_by_state
FROM sales s
LEFT JOIN returns r
    ON s.credit_rating = r.credit_rating
    AND s.gender = r.gender
ORDER BY net_profit_after_returns DESC
LIMIT 100
