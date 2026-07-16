WITH wp_counts AS (
    SELECT wp_customer_sk,
           COUNT(*) AS wp_cnt
    FROM web_page
    GROUP BY wp_customer_sk
),
filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_ticket_number,
        td.t_hour,
        c.c_birth_year
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_amt > 0
      AND td.t_hour BETWEEN 8 AND 18
      AND ib.ib_upper_bound >= 50000
      AND c.c_birth_year >= 1980
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.s_state,
    agg.t_hour,
    agg.total_net_loss,
    agg.total_return_qty,
    agg.avg_return_amt,
    agg.distinct_tickets,
    agg.avg_pages_per_customer,
    agg.avg_customer_birth_year,
    RANK() OVER (PARTITION BY agg.s_state ORDER BY agg.total_net_loss DESC) AS state_store_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        fr.t_hour,
        SUM(fr.sr_net_loss) AS total_net_loss,
        SUM(fr.sr_return_quantity) AS total_return_qty,
        AVG(fr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT fr.sr_ticket_number) AS distinct_tickets,
        AVG(COALESCE(wp.wp_cnt, 0)) AS avg_pages_per_customer,
        AVG(fr.c_birth_year) AS avg_customer_birth_year
    FROM filtered_returns fr
    JOIN store s ON fr.sr_store_sk = s.s_store_sk
    LEFT JOIN wp_counts wp ON fr.sr_customer_sk = wp.wp_customer_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        fr.t_hour
) agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
