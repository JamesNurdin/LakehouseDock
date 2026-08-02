WITH sales_returns AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_ticket_number AS sr_ticket_number,
        sr.sr_store_sk AS sr_store_sk
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_store_sk = sr.sr_store_sk
),
agg AS (
    SELECT
        s.s_state,
        s.s_city,
        s.s_store_name,
        SUM(COALESCE(ss_ext_sales_price, 0)) AS total_sales_amount,
        SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_return_amount_inc_tax,
        SUM(COALESCE(ss_net_profit, 0)) - SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS net_profit
    FROM sales_returns sr_combined
    JOIN store s
        ON s.s_store_sk = COALESCE(sr_combined.ss_store_sk, sr_combined.sr_store_sk)
    WHERE s.s_division_id = 1
      AND s.s_floor_space > 8000000
      AND COALESCE(sr_combined.ss_ext_tax, 0) > 100.00
      AND COALESCE(sr_combined.sr_return_amt_inc_tax, 0) > 500.00
    GROUP BY GROUPING SETS (
        (s.s_state, s.s_city, s.s_store_name),
        (s.s_state, s.s_city),
        (s.s_state),
        ()
    )
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY net_profit DESC) AS rank_in_state
    FROM agg
)
SELECT
    s_state,
    s_city,
    s_store_name,
    total_sales_amount,
    total_return_amount_inc_tax,
    net_profit,
    CASE WHEN s_store_name IS NOT NULL THEN rank_in_state END AS store_rank_in_state,
    (SELECT AVG(ss_ext_sales_price) FROM store_sales) AS avg_sale_price
FROM ranked
ORDER BY s_state, store_rank_in_state
LIMIT 100
