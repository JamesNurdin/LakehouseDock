WITH returns_by_reason AS (
    /* Aggregate store returns by month, category and reason */
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY dr.d_year, dr.d_month_seq, i.i_category, r.r_reason_desc
    UNION ALL
    /* Aggregate web returns by month, category and reason */
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        r.r_reason_desc,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY dr.d_year, dr.d_month_seq, i.i_category, r.r_reason_desc
),
top_reason AS (
    /* Pick the reason with the highest loss for each month & category */
    SELECT
        d_year,
        d_month_seq,
        i_category,
        r_reason_desc,
        total_return_qty,
        total_return_amt,
        total_return_loss,
        ROW_NUMBER() OVER (
            PARTITION BY d_year, d_month_seq, i_category
            ORDER BY total_return_loss DESC
        ) AS rn
    FROM returns_by_reason
),
sales_month_category AS (
    /* Aggregate web sales by month and category */
    SELECT
        dr.d_year,
        dr.d_month_seq,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM web_sales ws
    JOIN date_dim dr ON ws.ws_sold_date_sk = dr.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY dr.d_year, dr.d_month_seq, i.i_category
)
SELECT
    tr.d_year,
    tr.d_month_seq,
    tr.i_category,
    tr.r_reason_desc AS top_return_reason,
    tr.total_return_qty,
    tr.total_return_amt,
    tr.total_return_loss,
    smc.total_sales_amount,
    smc.total_sales_profit,
    (smc.total_sales_profit - tr.total_return_loss) AS net_profit_after_top_return_loss
FROM top_reason tr
JOIN sales_month_category smc
    ON tr.d_year = smc.d_year
   AND tr.d_month_seq = smc.d_month_seq
   AND tr.i_category = smc.i_category
WHERE tr.rn = 1
ORDER BY tr.d_year, tr.d_month_seq, tr.i_category
