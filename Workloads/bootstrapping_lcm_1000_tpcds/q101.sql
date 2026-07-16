WITH base AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        s.s_city AS s_city,
        s.s_state AS s_state,
        d_sales.d_year AS sales_year,
        hd_sales.hd_buy_potential AS sales_buy_potential,
        hd_refunded.hd_buy_potential AS refunded_buy_potential,
        hd_returning.hd_buy_potential AS returning_buy_potential,
        SUM(ss.ss_net_profit) AS total_sales_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM
        store_sales ss
        JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
        JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
        JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
        JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE
        d_sales.d_year BETWEEN 2000 AND 2005
        AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sales.d_year,
        hd_sales.hd_buy_potential,
        hd_refunded.hd_buy_potential,
        hd_returning.hd_buy_potential
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    sales_year,
    sales_buy_potential,
    refunded_buy_potential,
    returning_buy_potential,
    total_sales_net_profit,
    total_return_amount,
    total_return_net_loss,
    distinct_sales_tickets,
    distinct_return_orders,
    (total_sales_net_profit - total_return_amount - total_return_net_loss) AS net_profit_after_returns,
    ROW_NUMBER() OVER (
        PARTITION BY sales_year
        ORDER BY (total_sales_net_profit - total_return_amount - total_return_net_loss) DESC
    ) AS profit_rank_by_year
FROM base
ORDER BY net_profit_after_returns DESC
LIMIT 100
