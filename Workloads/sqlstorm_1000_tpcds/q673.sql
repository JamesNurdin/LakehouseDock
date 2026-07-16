WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_item_sk, ss.ss_customer_sk
),
returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_store_sk AS store_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt) AS return_amt,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk, sr.sr_item_sk, sr.sr_customer_sk
)
SELECT
    d.d_year,
    st.s_store_name,
    i.i_item_id,
    c.c_customer_id,
    COALESCE(s.net_paid, 0) - COALESCE(r.return_amt, 0) AS net_revenue,
    COALESCE(s.net_profit, 0) - COALESCE(r.net_loss, 0) AS net_profit,
    COALESCE(s.sales_cnt, 0) AS sales_transactions,
    COALESCE(r.return_cnt, 0) AS return_transactions
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.date_sk = r.date_sk
   AND s.store_sk = r.store_sk
   AND s.item_sk = r.item_sk
   AND s.customer_sk = r.customer_sk
JOIN date_dim d ON COALESCE(s.date_sk, r.date_sk) = d.d_date_sk
JOIN store st ON COALESCE(s.store_sk, r.store_sk) = st.s_store_sk
JOIN item i ON COALESCE(s.item_sk, r.item_sk) = i.i_item_sk
JOIN customer c ON COALESCE(s.customer_sk, r.customer_sk) = c.c_customer_sk
WHERE d.d_year = 2002
ORDER BY net_revenue DESC
LIMIT 100
