WITH sales_data AS (
    SELECT
        ss.ss_ticket_number,
        s.s_state,
        d.d_month_seq AS month_seq,
        d.d_year,
        ss.ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss.ss_net_profit AS net_profit,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        REGEXP_EXTRACT(c.c_last_name, '^([A-Z])', 1) AS last_initial,
        s.s_city
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(c.c_first_name, '^[AEIOU].*')
      AND s.s_city LIKE '%York%'
),
agg AS (
    SELECT
        s_state,
        month_seq,
        SUM(net_paid_inc_tax) AS total_sales,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM sales_data
    GROUP BY ROLLUP(s_state, month_seq)
    HAVING (s_state IS NOT NULL OR month_seq IS NOT NULL)
       AND SUM(net_paid_inc_tax) > 10000
)
SELECT
    s_state,
    month_seq,
    total_sales,
    total_profit,
    txn_count,
    state_rank
FROM (
    SELECT
        s_state,
        month_seq,
        total_sales,
        total_profit,
        txn_count,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_sales DESC) AS state_rank
    FROM agg
) t
WHERE state_rank <= 3
ORDER BY s_state, state_rank
LIMIT 100
