WITH sales AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        sr.sr_store_sk,
        d.d_year   AS return_year,
        d.d_month_seq AS return_month_seq,
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    sales.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    SUM(sales.ss_ext_sales_price)                     AS total_sales_amount,
    SUM(sales.ss_quantity)                            AS total_units_sold,
    SUM(sales.ss_ext_discount_amt)                    AS total_discount_amount,
    SUM(sales.ss_net_profit)                          AS total_net_profit,
    COALESCE(SUM(returns.sr_return_quantity), 0)      AS total_units_returned,
    COALESCE(SUM(returns.sr_return_amt), 0)           AS total_return_amount,
    CASE WHEN SUM(sales.ss_quantity) = 0 THEN 0
         ELSE COALESCE(SUM(returns.sr_return_quantity), 0) * 100.0 / SUM(sales.ss_quantity)
    END                                               AS return_rate_pct,
    CASE WHEN SUM(sales.ss_quantity) = 0 THEN 0
         ELSE SUM(sales.ss_ext_discount_amt) * 1.0 / SUM(sales.ss_quantity)
    END                                               AS avg_discount_per_unit
FROM sales
LEFT JOIN returns
    ON sales.ss_ticket_number = returns.sr_ticket_number
   AND sales.ss_item_sk        = returns.sr_item_sk
   AND sales.ss_store_sk       = returns.sr_store_sk
   AND returns.return_year    = sales.d_year
   AND returns.return_month_seq = sales.d_month_seq
GROUP BY sales.s_store_name, sales.d_year, sales.d_month_seq
ORDER BY sales.s_store_name, sales.d_year, sales.d_month_seq
