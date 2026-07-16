WITH reason_counts AS (
    SELECT
        d.d_fy_quarter_seq,
        t.t_shift,
        r.r_reason_desc,
        COUNT(*) AS reason_cnt,
        ROW_NUMBER() OVER (PARTITION BY d.d_fy_quarter_seq, t.t_shift ORDER BY COUNT(*) DESC) AS rn
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_current_quarter = 'Y'
      AND t.t_shift = 'Evening'
    GROUP BY d.d_fy_quarter_seq, t.t_shift, r.r_reason_desc
),
top_reason AS (
    SELECT d_fy_quarter_seq, t_shift, r_reason_desc AS top_return_reason
    FROM reason_counts
    WHERE rn = 1
),
returns_agg AS (
    SELECT
        d.d_fy_quarter_seq,
        t.t_shift,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns_inc_tax,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_current_quarter = 'Y'
      AND t.t_shift = 'Evening'
    GROUP BY d.d_fy_quarter_seq, t.t_shift
)
SELECT
    s.s_store_name,
    d.d_fy_quarter_seq AS fiscal_quarter,
    p.p_promo_name,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    COALESCE(r.total_returns_inc_tax, 0) AS total_returns_inc_tax,
    CASE WHEN SUM(ss.ss_net_paid_inc_tax) > 0 THEN
        COALESCE(r.total_returns_inc_tax, 0) / SUM(ss.ss_net_paid_inc_tax) * 100
    END AS return_rate_pct,
    tr.top_return_reason,
    ROW_NUMBER() OVER (PARTITION BY d.d_fy_quarter_seq ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg r ON r.d_fy_quarter_seq = d.d_fy_quarter_seq AND r.t_shift = t.t_shift
LEFT JOIN top_reason tr ON tr.d_fy_quarter_seq = d.d_fy_quarter_seq AND tr.t_shift = t.t_shift
WHERE d.d_current_quarter = 'Y'
  AND s.s_state = 'CA'
  AND (p.p_channel_tv = 'Y' OR p.p_channel_tv IS NULL)
  AND t.t_shift = 'Evening'
GROUP BY
    s.s_store_name,
    d.d_fy_quarter_seq,
    p.p_promo_name,
    r.total_returns_inc_tax,
    tr.top_return_reason
HAVING SUM(ss.ss_net_paid_inc_tax) > 50000
ORDER BY total_sales_inc_tax DESC
LIMIT 10
