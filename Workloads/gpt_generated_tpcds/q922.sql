WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, hd.hd_buy_potential
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        hd.hd_buy_potential,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY s.s_store_sk, d.d_year, hd.hd_buy_potential
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.hd_buy_potential,
    sa.total_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    sa.total_profit,
    CASE WHEN sa.total_sales > 0 THEN (COALESCE(ra.total_returns, 0) / sa.total_sales) ELSE 0 END AS return_rate,
    sa.num_sales,
    COALESCE(ra.num_returns, 0) AS num_returns
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.d_year = ra.d_year
    AND sa.hd_buy_potential = ra.hd_buy_potential
ORDER BY sa.total_sales DESC
LIMIT 100
