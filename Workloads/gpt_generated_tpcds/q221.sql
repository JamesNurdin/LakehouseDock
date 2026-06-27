WITH sales AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           cs.cs_net_paid_inc_tax AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year >= 2000
),
catalog_ret AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year >= 2000
),
web_ret AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           wr.wr_return_amt AS return_amount,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year >= 2000
)
SELECT s.category,
       s.year,
       SUM(s.net_paid) AS total_sales,
       SUM(s.net_profit) AS total_profit,
       COALESCE(SUM(r.return_amount), 0) AS total_return_amount,
       COALESCE(SUM(r.net_loss), 0) AS total_return_loss,
       COALESCE(SUM(w.return_amount), 0) AS total_web_return_amount,
       COALESCE(SUM(w.net_loss), 0) AS total_web_return_loss,
       SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) - COALESCE(SUM(w.net_loss), 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN catalog_ret r
       ON s.category = r.category
      AND s.year = r.year
LEFT JOIN web_ret w
       ON s.category = w.category
      AND s.year = w.year
GROUP BY s.category, s.year
ORDER BY net_profit_after_returns DESC
LIMIT 10
