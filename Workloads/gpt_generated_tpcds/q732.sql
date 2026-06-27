WITH store_sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        hd.hd_buy_potential AS buy_potential,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2000
    GROUP BY s.s_store_name, hd.hd_buy_potential, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        s.s_store_name AS store_name,
        hd.hd_buy_potential AS buy_potential,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        SUM(sr.sr_net_loss) AS total_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year >= 2000
    GROUP BY s.s_store_name, hd.hd_buy_potential, d.d_year, d.d_month_seq
)
SELECT
    COALESCE(ss.store_name, sr.store_name) AS store_name,
    COALESCE(ss.buy_potential, sr.buy_potential) AS buy_potential,
    COALESCE(ss.year, sr.year) AS year,
    COALESCE(ss.month_seq, sr.month_seq) AS month_seq,
    ss.total_sales,
    ss.total_profit,
    sr.total_loss,
    (COALESCE(ss.total_profit, 0) - COALESCE(sr.total_loss, 0)) AS net_profit_after_returns
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
    ON ss.store_name = sr.store_name
   AND ss.buy_potential = sr.buy_potential
   AND ss.year = sr.year
   AND ss.month_seq = sr.month_seq
ORDER BY net_profit_after_returns DESC
LIMIT 100
