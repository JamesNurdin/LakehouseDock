WITH sales_data AS (
   SELECT d.d_year, d.d_month_seq, i.i_category, i.i_product_name,
          cs.cs_net_paid AS net_paid,
          cs.cs_ext_discount_amt AS discount_amt,
          cs.cs_net_profit AS net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year, d.d_month_seq, i.i_category, i.i_product_name,
          ws.ws_net_paid,
          ws.ws_ext_discount_amt,
          ws.ws_net_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year, d.d_month_seq, i.i_category, i.i_product_name,
          ss.ss_net_paid,
          ss.ss_ext_discount_amt,
          ss.ss_net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
sales_agg AS (
   SELECT d_year,
          d_month_seq,
          i_category,
          sum(net_paid) AS total_net_paid,
          sum(discount_amt) AS total_discount,
          sum(net_profit) AS total_net_profit
   FROM sales_data
   GROUP BY d_year, d_month_seq, i_category
),
returns_data AS (
   SELECT d.d_year, d.d_month_seq, i.i_category, cr.cr_net_loss AS net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year, d.d_month_seq, i.i_category, wr.wr_net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year, d.d_month_seq, i.i_category, sr.sr_net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
returns_agg AS (
   SELECT d_year,
          d_month_seq,
          i_category,
          sum(net_loss) AS total_return_loss
   FROM returns_data
   GROUP BY d_year, d_month_seq, i_category
),
combined AS (
   SELECT
       COALESCE(s.d_year, r.d_year) AS d_year,
       COALESCE(s.d_month_seq, r.d_month_seq) AS d_month_seq,
       COALESCE(s.i_category, r.i_category) AS i_category,
       COALESCE(s.total_net_paid, 0) AS total_net_paid,
       COALESCE(s.total_discount, 0) AS total_discount,
       COALESCE(s.total_net_profit, 0) AS total_net_profit,
       COALESCE(r.total_return_loss, 0) AS total_return_loss,
       (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
       CASE WHEN COALESCE(s.total_net_paid, 0) = 0 THEN NULL
            ELSE COALESCE(s.total_discount, 0) / COALESCE(s.total_net_paid, 0)
       END AS discount_ratio
   FROM sales_agg s
   FULL OUTER JOIN returns_agg r
     ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
   WHERE (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_loss, 0)) > 0
),
ranked AS (
   SELECT
       d_year,
       d_month_seq,
       i_category,
       total_net_paid,
       total_discount,
       total_net_profit,
       total_return_loss,
       net_profit_after_returns,
       discount_ratio,
       row_number() OVER (PARTITION BY d_year, d_month_seq ORDER BY net_profit_after_returns DESC) AS profit_rank
   FROM combined
)
SELECT
   d_year,
   d_month_seq,
   i_category,
   total_net_paid,
   total_discount,
   total_net_profit,
   total_return_loss,
   net_profit_after_returns,
   discount_ratio,
   profit_rank
FROM ranked
WHERE profit_rank <= 3
ORDER BY d_year DESC, d_month_seq DESC, profit_rank
