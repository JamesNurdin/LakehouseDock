WITH sales AS (
    SELECT
        'store' AS channel,
        st.s_state AS state,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY st.s_state, d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        'catalog' AS channel,
        cc.cc_state AS state,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_qty
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cc.cc_state, d.d_year, d.d_month_seq
),
returns AS (
    SELECT
        'store' AS channel,
        st.s_state AS state,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY st.s_state, d.d_year, d.d_month_seq
    UNION ALL
    SELECT
        'catalog' AS channel,
        cc.cc_state AS state,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cc.cc_state, d.d_year, d.d_month_seq
),
combined AS (
    SELECT
        s.channel,
        s.state,
        s.d_year,
        s.d_month_seq,
        s.total_net_paid,
        s.total_net_profit,
        s.total_qty,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_adj,
        ROW_NUMBER() OVER (PARTITION BY s.state, s.d_year, s.d_month_seq ORDER BY (s.total_net_profit - COALESCE(r.total_return_loss, 0)) DESC) AS profit_rank
    FROM sales s
    LEFT JOIN returns r
      ON s.channel = r.channel
      AND s.state = r.state
      AND s.d_year = r.d_year
      AND s.d_month_seq = r.d_month_seq
)
SELECT
    channel,
    state,
    d_year,
    d_month_seq,
    total_net_paid,
    total_qty,
    total_return_amount,
    total_return_qty,
    net_profit_adj,
    profit_rank
FROM combined
WHERE profit_rank <= 3
ORDER BY state, d_year, d_month_seq, profit_rank
