WITH sales_returns AS (
    SELECT
        ss.ss_sold_date_sk,
        ds.d_year,
        ds.d_month_seq,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_category,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS sr_return_quantity,
        COALESCE(sr.sr_return_amt_inc_tax, 0) AS sr_return_amt_inc_tax,
        COALESCE(sr.sr_net_loss, 0) AS sr_net_loss
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE ds.d_year = 2001
)
SELECT
    s_store_name,
    d_year,
    d_month_seq,
    i_category,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(sr_return_quantity) AS total_quantity_returned,
    SUM(ss_ext_sales_price) AS total_sales_amount,
    SUM(sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(ss_net_profit) - SUM(sr_net_loss) AS net_profit_after_returns,
    SUM(ss_net_profit) AS total_sales_net_profit,
    SUM(sr_net_loss) AS total_return_net_loss
FROM sales_returns
GROUP BY
    s_store_name,
    d_year,
    d_month_seq,
    i_category
HAVING
    SUM(ss_net_profit) - SUM(sr_net_loss) > 0
ORDER BY
    d_year,
    d_month_seq,
    s_store_name,
    i_category
