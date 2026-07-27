WITH monthly_agg AS (
    SELECT
        i.i_category AS category,
        d.d_month_seq AS month_seq,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS discount_cost_total
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
      AND i.i_manufact_id IN (169, 995)
      AND p.p_channel_dmail = 'Y'
      AND EXISTS (
          SELECT 1 FROM store s
          WHERE s.s_closed_date_sk = d.d_date_sk
            AND s.s_state = 'CA'
      )
    GROUP BY i.i_category, d.d_month_seq
)
SELECT
    category,
    AVG(discount_cost_total) AS avg_monthly_discount_cost,
    SUM(total_return_amt) AS total_return_amt_all_months,
    CASE
        WHEN SUM(total_return_amt) > 0 THEN SUM(total_return_qty) / SUM(total_return_amt)
        ELSE NULL
    END AS qty_per_dollar
FROM monthly_agg
GROUP BY category
ORDER BY avg_monthly_discount_cost DESC
LIMIT 100
