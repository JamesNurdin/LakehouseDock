WITH
store_sales_raw AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ss.ss_store_sk AS store_sk,
        'store' AS channel,
        ss.ss_quantity AS qty,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_sales_raw AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        CAST(NULL AS integer) AS store_sk,
        'web' AS channel,
        ws.ws_quantity AS qty,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_sales_raw AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        CAST(NULL AS integer) AS store_sk,
        'catalog' AS channel,
        cs.cs_quantity AS qty,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
combined_sales AS (
    SELECT * FROM store_sales_raw
    UNION ALL
    SELECT * FROM web_sales_raw
    UNION ALL
    SELECT * FROM catalog_sales_raw
),
store_returns_raw AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sr.sr_store_sk AS store_sk,
        SUM(sr.sr_return_amt_inc_tax) AS return_amount,
        SUM(sr.sr_net_loss) AS return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category, sr.sr_store_sk
),
web_returns_raw AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        CAST(NULL AS integer) AS store_sk,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount,
        SUM(wr.wr_net_loss) AS return_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_raw AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        CAST(NULL AS integer) AS store_sk,
        SUM(cr.cr_return_amt_inc_tax) AS return_amount,
        SUM(cr.cr_net_loss) AS return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined_returns AS (
    SELECT * FROM store_returns_raw
    UNION ALL
    SELECT * FROM web_returns_raw
    UNION ALL
    SELECT * FROM catalog_returns_raw
),
sales_agg AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.i_category,
        s.store_sk,
        s.channel,
        SUM(s.qty) AS total_qty,
        SUM(s.net_paid) AS total_sales,
        SUM(s.net_profit) AS total_profit,
        SUM(s.discount_amt) AS total_discount,
        COUNT(*) AS sales_txn_cnt
    FROM combined_sales s
    GROUP BY s.d_year, s.d_month_seq, s.i_category, s.store_sk, s.channel
),
returns_agg AS (
    SELECT
        r.d_year,
        r.d_month_seq,
        r.i_category,
        r.store_sk,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.return_loss) AS total_return_loss,
        SUM(r.return_cnt) AS return_txn_cnt
    FROM combined_returns r
    GROUP BY r.d_year, r.d_month_seq, r.i_category, r.store_sk
),
final_agg AS (
    SELECT
        sa.d_year,
        sa.d_month_seq,
        sa.i_category,
        sa.store_sk,
        sa.channel,
        sa.total_qty,
        sa.total_sales,
        sa.total_profit,
        sa.total_discount,
        sa.sales_txn_cnt,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        COALESCE(ra.return_txn_cnt, 0) AS return_txn_cnt,
        CASE WHEN sa.total_sales > 0 THEN COALESCE(ra.total_return_amount, 0) / sa.total_sales ELSE 0 END AS return_rate
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.d_year = ra.d_year
       AND sa.d_month_seq = ra.d_month_seq
       AND sa.i_category = ra.i_category
       AND ( (sa.store_sk = ra.store_sk) OR (sa.store_sk IS NULL AND ra.store_sk IS NULL) )
),
ranked AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (PARTITION BY f.d_year, f.d_month_seq, f.i_category ORDER BY f.total_profit DESC) AS profit_rank
    FROM final_agg f
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.i_category,
    r.store_sk,
    st.s_store_id,
    st.s_store_name,
    r.channel,
    r.total_qty,
    r.total_sales,
    r.total_profit,
    r.total_discount,
    r.sales_txn_cnt,
    r.total_return_amount,
    r.total_return_loss,
    r.return_txn_cnt,
    r.return_rate,
    r.profit_rank
FROM ranked r
LEFT JOIN store st ON r.store_sk = st.s_store_sk
WHERE r.profit_rank <= 5
ORDER BY r.d_year, r.d_month_seq, r.i_category, r.profit_rank
