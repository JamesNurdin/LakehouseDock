/*
  Analytical query: Net profit and return metrics per store, month, buy‑potential and sales shift for the year 2002.
  Joins use only the permitted keys between store_sales, store_returns, date_dim, time_dim, household_demographics and reason.
*/
WITH sales_returns AS (
    SELECT
        ss.ss_store_sk,
        ds.d_year,
        ds.d_month_seq,
        hd.hd_buy_potential,
        ts.t_shift AS sales_shift,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        tr.t_shift AS return_shift
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN time_dim ts ON ss.ss_sold_time_sk = ts.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    LEFT JOIN time_dim tr ON sr.sr_return_time_sk = tr.t_time_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ds.d_year = 2002
      AND (dr.d_year = 2002 OR dr.d_year IS NULL)
)
SELECT
    ss_store_sk,
    d_year,
    d_month_seq,
    hd_buy_potential,
    sales_shift,
    r_reason_desc,
    SUM(ss_net_paid) AS total_sales_net_paid,
    SUM(ss_net_profit) AS total_sales_net_profit,
    COALESCE(SUM(sr_net_loss), 0) AS total_return_net_loss,
    SUM(ss_net_profit) - COALESCE(SUM(sr_net_loss), 0) AS net_profit_after_returns,
    COUNT(sr_return_amt) AS return_count,
    CASE WHEN COUNT(sr_return_amt) > 0 THEN SUM(sr_return_amt) / COUNT(sr_return_amt) ELSE NULL END AS avg_return_amount,
    COUNT(DISTINCT return_shift) AS distinct_return_shifts
FROM sales_returns
GROUP BY
    ss_store_sk,
    d_year,
    d_month_seq,
    hd_buy_potential,
    sales_shift,
    r_reason_desc
ORDER BY
    ss_store_sk,
    d_year,
    d_month_seq,
    hd_buy_potential,
    sales_shift,
    r_reason_desc
