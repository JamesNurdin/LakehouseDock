WITH sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        ss.ss_item_sk,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        sr.sr_net_loss,
        sr.sr_item_sk,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
joined AS (
    SELECT
        s.ss_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        st.s_store_name,
        st.s_state,
        SUM(s.ss_ext_sales_price) AS total_sales,
        SUM(s.ss_ext_discount_amt) AS total_discount,
        SUM(s.ss_net_profit) AS total_profit,
        COALESCE(SUM(r.sr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(r.sr_refunded_cash), 0) AS total_refunded_cash,
        COALESCE(SUM(r.sr_net_loss), 0) AS total_return_loss
    FROM sales s
    JOIN store st
        ON s.ss_store_sk = st.s_store_sk
    JOIN date_dim d
        ON s.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN returns r
        ON s.ss_item_sk = r.sr_item_sk
        AND s.ss_store_sk = r.sr_store_sk
        AND s.ss_ticket_number = r.sr_ticket_number
    GROUP BY s.ss_store_sk, d.d_year, d.d_month_seq, st.s_store_name, st.s_state
)
SELECT
    store_sk,
    s_store_name,
    s_state,
    d_year,
    d_month_seq,
    total_sales,
    total_discount,
    total_profit,
    total_return_amount,
    total_refunded_cash,
    total_return_loss,
    (total_profit - total_return_loss) AS net_profit_after_returns
FROM joined
ORDER BY d_year, d_month_seq, total_sales DESC
