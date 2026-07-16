WITH monthly_store_sales AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_net_paid) AS sales,
        SUM(ss.ss_ext_discount_amt) AS discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_closed_date_sk IS NULL
      AND d.d_year >= 2020
      AND ca.ca_country = 'United States'
      AND ca.ca_location_type = 'single family'
    GROUP BY s.s_store_id, s.s_state, d.d_year, d.d_month_seq
)
SELECT
    ms.s_store_id,
    ms.s_state,
    ms.d_year,
    ms.d_month_seq,
    ms.profit,
    ms.sales,
    ms.discount,
    ms.tickets,
    ROUND(ms.profit / NULLIF(ms.sales, 0), 4) AS profit_margin,
    SUM(ms.profit) OVER (PARTITION BY ms.s_state ORDER BY ms.d_year, ms.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_state_profit,
    ROW_NUMBER() OVER (PARTITION BY ms.s_state ORDER BY ms.profit DESC) AS profit_rank_state
FROM monthly_store_sales ms
WHERE ms.profit > 5000
ORDER BY ms.s_state, ms.profit DESC
LIMIT 200
