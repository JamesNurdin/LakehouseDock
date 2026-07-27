WITH sales_returns AS (
    SELECT
        s.s_store_id,
        s.s_state,
        td.t_hour,
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND hd.hd_income_band_sk BETWEEN 10 AND 20
        AND s.s_state = 'CA'
        AND sr.sr_return_quantity > 10
        AND r.r_reason_desc LIKE '%Damaged%'
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_customer_sk = ss.ss_customer_sk
              AND wp.wp_type = 'product'
        )
    GROUP BY s.s_store_id, s.s_state, td.t_hour, ss.ss_customer_sk
),
store_hour_agg AS (
    SELECT
        s_store_id,
        s_state,
        t_hour,
        SUM(total_profit) AS sum_profit,
        SUM(total_loss) AS sum_loss,
        COUNT(DISTINCT ss_customer_sk) AS uniq_customers,
        SUM(total_quantity) AS sum_quantity
    FROM sales_returns
    GROUP BY s_store_id, s_state, t_hour
),
distinct_profits AS (
    SELECT DISTINCT
        s_state,
        sum_profit
    FROM store_hour_agg
    WHERE sum_profit > 1000
)
SELECT
    dp.s_state,
    AVG(dp.sum_profit) AS avg_profit_per_state,
    COUNT(*) AS profit_rows
FROM distinct_profits dp
GROUP BY dp.s_state
HAVING AVG(dp.sum_profit) > 2000
ORDER BY avg_profit_per_state DESC
LIMIT 100
