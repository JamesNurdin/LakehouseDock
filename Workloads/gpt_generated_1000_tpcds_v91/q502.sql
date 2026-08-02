WITH base_data AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_city,
        sr.sr_return_amt_inc_tax,
        sr.sr_refunded_cash,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_net_loss,
        sr.sr_ticket_number
    FROM store s
    JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY')
        AND s.s_gmt_offset >= -5.00
        AND s.s_tax_percentage BETWEEN 5.00 AND 9.00
        AND s.s_hours LIKE '8AM-%'
        AND s.s_rec_start_date >= DATE '2000-01-01'
        AND s.s_rec_end_date <= DATE '2022-12-31'
        AND sr.sr_refunded_cash > 100.00
        AND sr.sr_fee < 50.00
        AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr_ex
            WHERE sr_ex.sr_store_sk = s.s_store_sk
                AND sr_ex.sr_refunded_cash > 5000
        )
),

agg1 AS (
    SELECT
        s_state,
        s_city,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        SUM(sr_fee) AS total_fee,
        SUM(sr_return_ship_cost) AS total_ship_cost,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr_ticket_number) AS cnt_tickets
    FROM base_data
    GROUP BY ROLLUP (s_state, s_city)
),

unioned AS (
    SELECT s_state, s_city, total_return_amt_inc_tax, total_refunded_cash, cnt_tickets
    FROM agg1
    WHERE total_return_amt_inc_tax > 5000

    UNION

    SELECT s_state, s_city, total_return_amt_inc_tax, total_refunded_cash, cnt_tickets
    FROM agg1
    WHERE cnt_tickets >= 20
),

final_agg AS (
    SELECT
        s_state,
        s_city,
        SUM(total_return_amt_inc_tax) AS sum_return_amt_inc_tax,
        SUM(total_refunded_cash) AS sum_refunded_cash,
        SUM(cnt_tickets) AS sum_cnt_tickets,
        AVG(total_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM unioned
    GROUP BY CUBE (s_state, s_city)
    HAVING SUM(total_return_amt_inc_tax) > 10000
)

SELECT
    s_state,
    s_city,
    sum_return_amt_inc_tax,
    sum_refunded_cash,
    sum_cnt_tickets,
    avg_return_amt_inc_tax
FROM final_agg
ORDER BY s_state, s_city
LIMIT 100
