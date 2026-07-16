WITH sales AS (
    SELECT
        ds.d_year,
        ds.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
returns AS (
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
agg AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.i_class,
        s.i_brand,
        s.ss_store_sk AS store_sk,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_net_profit) AS total_sales_profit,
        COALESCE(SUM(r.sr_return_quantity), 0) AS total_quantity_returned,
        COALESCE(SUM(r.sr_net_loss), 0) AS total_return_loss,
        SUM(s.ss_net_profit) - COALESCE(SUM(r.sr_net_loss), 0) AS net_profit_after_returns
    FROM sales s
    LEFT JOIN returns r
        ON s.ss_ticket_number = r.sr_ticket_number
        AND s.ss_item_sk = r.sr_item_sk
        AND s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
    GROUP BY
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.i_class,
        s.i_brand,
        s.ss_store_sk
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    store_sk,
    total_quantity_sold,
    total_sales_profit,
    total_quantity_returned,
    total_return_loss,
    net_profit_after_returns,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM agg
ORDER BY d_year, d_month_seq, profit_rank
