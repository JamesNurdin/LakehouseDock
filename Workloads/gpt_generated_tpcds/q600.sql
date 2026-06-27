WITH sales_agg AS (
    SELECT s.s_store_id,
           year(d.d_date) AS sales_year,
           month(d.d_date) AS sales_month,
           sum(ss.ss_net_paid) AS total_net_paid,
           sum(ss.ss_net_profit) AS total_net_profit,
           count(*) AS sales_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_id, year(d.d_date), month(d.d_date)
),
returns_agg AS (
    SELECT s.s_store_id,
           year(d.d_date) AS return_year,
           month(d.d_date) AS return_month,
           sum(sr.sr_net_loss) AS total_net_loss,
           sum(sr.sr_return_amt) AS total_return_amount,
           count(*) AS return_transactions
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY s.s_store_id, year(d.d_date), month(d.d_date)
)
SELECT s_agg.s_store_id,
       s_agg.sales_year,
       s_agg.sales_month,
       s_agg.total_net_paid,
       s_agg.total_net_profit,
       COALESCE(r_agg.total_return_amount, 0) AS total_return_amount,
       COALESCE(r_agg.total_net_loss, 0) AS total_net_loss,
       s_agg.total_net_profit - COALESCE(r_agg.total_net_loss, 0) AS net_profit_after_returns,
       s_agg.sales_transactions,
       COALESCE(r_agg.return_transactions, 0) AS return_transactions
FROM sales_agg s_agg
LEFT JOIN returns_agg r_agg
  ON s_agg.s_store_id = r_agg.s_store_id
 AND s_agg.sales_year = r_agg.return_year
 AND s_agg.sales_month = r_agg.return_month
ORDER BY s_agg.sales_year,
         s_agg.sales_month,
         s_agg.total_net_paid DESC
