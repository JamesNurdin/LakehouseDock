WITH sales_agg AS (
    SELECT
        st.s_store_name AS s_store_name,
        d_sales.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d_sales.d_year = 2001
    GROUP BY st.s_store_name, d_sales.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        st.s_store_name AS s_store_name,
        d_return.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN store st
        ON sr.sr_store_sk = st.s_store_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE d_return.d_year = 2001
    GROUP BY st.s_store_name, d_return.d_month_seq, i.i_category
)
SELECT
    s.s_store_name,
    s.d_month_seq,
    s.i_category,
    s.distinct_customers,
    s.total_sales_amount,
    s.total_sales_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.s_store_name = r.s_store_name
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
ORDER BY s.s_store_name, s.d_month_seq, s.i_category
