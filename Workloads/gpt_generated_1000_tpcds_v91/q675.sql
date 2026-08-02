WITH sample_store_returns AS (
    SELECT * FROM store_returns TABLESAMPLE BERNOULLI (10)
),
reason_words AS (
    SELECT r.r_reason_sk, word
    FROM reason r
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
),
joined AS (
    SELECT
        s.s_store_id,
        s.s_store_sk,
        r_wr.r_reason_desc,
        r_wr.r_reason_id,
        w.w_city,
        cp.cp_department,
        t.t_hour,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_refunded_cash,
        sr.sr_net_loss,
        cr.cr_return_amount,
        wr.wr_net_loss,
        ws.ws_net_paid,
        rw.word
    FROM
        sample_store_returns sr
    FULL OUTER JOIN time_dim t
        ON t.t_time_sk = sr.sr_return_time_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    INNER JOIN catalog_returns cr
        ON t.t_time_sk = cr.cr_returned_time_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_returns wr
        ON t.t_time_sk = wr.wr_returned_time_sk
    INNER JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN reason_words rw
        ON r_wr.r_reason_sk = rw.r_reason_sk
    WHERE
        t.t_hour = 14
        AND s.s_state = 'CA'
        AND r_wr.r_reason_id = 'AAAAAAAAIAAAAAAA'
        AND w.w_city = 'Seattle'
        AND cp.cp_department = 'Sports'
        AND s.s_rec_start_date >= DATE '1998-01-01'
),
agg AS (
    SELECT
        s_store_id,
        s_store_sk,
        r_reason_desc,
        word,
        t_hour,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        SUM(sr_refunded_cash) AS total_store_refunded_cash,
        SUM(sr_net_loss) AS total_store_net_loss,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(wr_net_loss) AS total_web_net_loss,
        SUM(ws_net_paid) AS total_web_sales,
        MIN(sr_return_quantity) AS min_store_return_qty,
        MAX(sr_return_quantity) AS max_store_return_qty,
        AVG(sr_return_quantity) AS avg_store_return_qty
    FROM joined
    GROUP BY
        s_store_id,
        s_store_sk,
        r_reason_desc,
        word,
        t_hour
)
SELECT
    s_store_id,
    r_reason_desc,
    word,
    t_hour,
    store_return_count,
    total_store_refunded_cash,
    total_store_net_loss,
    total_catalog_return_amount,
    total_web_net_loss,
    total_web_sales,
    min_store_return_qty,
    max_store_return_qty,
    avg_store_return_qty,
    (
        SELECT SUM(sr2.sr_refunded_cash)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = agg.s_store_sk
    ) AS total_refunded_cash_all_returns,
    RANK() OVER (ORDER BY total_store_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_store_net_loss DESC
LIMIT 100
