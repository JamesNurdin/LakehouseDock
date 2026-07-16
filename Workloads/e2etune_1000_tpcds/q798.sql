WITH sales_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           d.d_moy AS month_num,
           SUM(ws.ws_ext_sales_price) AS total_sales_amount,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS sales_transactions
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY i.i_category, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT i.i_category AS category,
           d.d_year AS year,
           d.d_moy AS month_num,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_net_loss) AS total_return_loss,
           COUNT(*) AS return_transactions,
           AVG(hd_ref.hd_vehicle_count) AS avg_vehicle_cnt_refunded,
           AVG(hd_ret.hd_vehicle_count) AS avg_vehicle_cnt_returning
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND cr.cr_refunded_hdemo_sk IN (6189, 2480, 3797)
      AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT s.category,
       s.year,
       s.month_num,
       s.total_sales_amount,
       s.total_profit,
       r.total_return_amount,
       r.total_return_loss,
       CASE WHEN s.total_sales_amount = 0 THEN 0
            ELSE r.total_return_amount / s.total_sales_amount END AS return_amount_ratio,
       CASE WHEN s.total_profit = 0 THEN 0
            ELSE r.total_return_loss / s.total_profit END AS return_loss_to_profit_ratio,
       r.avg_vehicle_cnt_refunded,
       r.avg_vehicle_cnt_returning,
       RANK() OVER (PARTITION BY s.year ORDER BY s.total_sales_amount DESC) AS sales_rank_year
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.category = r.category
 AND s.year = r.year
 AND s.month_num = r.month_num
ORDER BY s.total_sales_amount DESC
LIMIT 100
