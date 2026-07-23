WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sales.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE
        d_sales.d_year = 2002
        AND ib.ib_lower_bound >= 50000
        AND s.s_market_manager = 'Dustin Kelly'
        AND hd.hd_buy_potential = '>10000'
        AND s.s_state = 'CA'
        AND d_closed.d_year > 2000
        AND EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
              AND sr.sr_item_sk = ss.ss_item_sk
              AND sr.sr_store_sk = s.s_store_sk
              AND sr.sr_hdemo_sk = hd.hd_demo_sk
              AND sr.sr_returned_date_sk = d_sales.d_date_sk
              AND sr.sr_net_loss > 0
        )
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sales.d_year
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.d_year,
    sa.total_sales,
    sa.total_net_profit,
    sa.distinct_tickets,
    (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = sa.d_year
    ) AS avg_yearly_net_profit,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN sa.total_net_profit > (
            SELECT AVG(ss3.ss_net_profit)
            FROM store_sales ss3
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_overall
FROM sales_agg sa
ORDER BY profit_rank, total_net_profit DESC
LIMIT 100
