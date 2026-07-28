WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cc.cc_name,
        cr.cr_return_amount,
        wr.wr_return_amt,
        cr.cr_net_loss,
        wr.wr_net_loss,
        cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.i_category = 'Sports'
      AND cc.cc_state = 'CA'
      AND s.s_state = 'CA'
      AND wp.wp_url LIKE 'http://www.example.com/%'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND p.p_cost > (
          SELECT AVG(p2.p_cost)
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
      )
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        cc_name,
        SUM(cr_return_amount) AS sum_cr_return_amount,
        SUM(wr_return_amt) AS sum_wr_return_amt,
        SUM(cr_net_loss + wr_net_loss) AS total_loss,
        COUNT(DISTINCT cr_order_number) AS distinct_orders
    FROM base
    GROUP BY ROLLUP (d_year, d_month_seq, i_category, cc_name)
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    cc_name,
    sum_cr_return_amount,
    sum_wr_return_amt,
    total_loss,
    CASE WHEN total_loss > 0 THEN 'Loss' ELSE 'Profit' END AS loss_indicator,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_loss DESC) AS rn
FROM agg
ORDER BY d_year DESC NULLS LAST, d_month_seq, total_loss DESC
LIMIT 100
