WITH sales_agg AS (
   SELECT
      ss.ss_store_sk AS store_sk,
      i.i_category AS category,
      d.d_year,
      d.d_month_seq,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY ss.ss_store_sk, i.i_category, d.d_year, d.d_month_seq
), returns_agg AS (
   SELECT
      sr.sr_store_sk AS store_sk,
      i.i_category AS category,
      d.d_year,
      d.d_month_seq,
      SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
      SUM(sr.sr_net_loss) AS total_return_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY sr.sr_store_sk, i.i_category, d.d_year, d.d_month_seq
)
SELECT
   s.s_store_name,
   s.s_state,
   a.category,
   a.d_year,
   a.d_month_seq,
   a.total_sales,
   COALESCE(r.total_return_amount, 0) AS total_return_amount,
   a.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_adj,
   RANK() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_sales DESC) AS sales_rank
FROM sales_agg a
JOIN store s ON a.store_sk = s.s_store_sk
LEFT JOIN returns_agg r
  ON a.store_sk = r.store_sk
 AND a.category = r.category
 AND a.d_year = r.d_year
 AND a.d_month_seq = r.d_month_seq
ORDER BY a.d_year, a.d_month_seq, sales_rank
LIMIT 100
