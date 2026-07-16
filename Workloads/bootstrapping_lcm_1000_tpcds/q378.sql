SELECT
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month_seq,
    d_closed.d_year AS store_closed_year,
    d_closed.d_current_month AS store_closed_month,
    s.s_store_id,
    s.s_city,
    hd_sales.hd_buy_potential AS sales_buy_potential,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_units_sold,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
    AVG(hd_sales.hd_income_band_sk) AS avg_income_band_sales,
    AVG(hd_refunded.hd_income_band_sk) AS avg_income_band_refunded,
    AVG(hd_returning.hd_income_band_sk) AS avg_income_band_returning,
    ROW_NUMBER() OVER (PARTITION BY d_return.d_year ORDER BY (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) DESC) AS profit_rank_within_year
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_return.d_date_sk
JOIN household_demographics hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_return.d_year = 2022
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    d_closed.d_year,
    d_closed.d_current_month,
    s.s_store_id,
    s.s_city,
    hd_sales.hd_buy_potential,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_buy_potential
ORDER BY net_profit_after_returns DESC
LIMIT 100
