WITH sales AS (
    SELECT i.i_category AS category, d.d_year AS sales_year, d.d_month_seq AS month_seq,
           ss.ss_net_paid AS net_paid, ss.ss_ext_discount_amt AS discount, ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT i.i_category, d.d_year, d.d_month_seq,
           cs.cs_net_paid, cs.cs_ext_discount_amt, cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT i.i_category, d.d_year, d.d_month_seq,
           ws.ws_net_paid, ws.ws_ext_discount_amt, ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales_agg AS (
    SELECT category, sales_year, month_seq,
           SUM(net_paid) AS total_sales,
           SUM(discount) AS total_discount,
           SUM(profit) AS total_profit
    FROM sales
    GROUP BY category, sales_year, month_seq
),
returns AS (
    SELECT i.i_category AS category, d.d_year AS sales_year, d.d_month_seq AS month_seq,
           cr.cr_net_loss AS return_loss, cr.cr_return_quantity AS return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT i.i_category, d.d_year, d.d_month_seq,
           sr.sr_net_loss, sr.sr_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT i.i_category, d.d_year, d.d_month_seq,
           wr.wr_net_loss, wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
returns_agg AS (
    SELECT category, sales_year, month_seq,
           SUM(return_loss) AS total_return_loss,
           SUM(return_qty) AS total_return_qty
    FROM returns
    GROUP BY category, sales_year, month_seq
)
SELECT
    s.category,
    s.sales_year,
    s.month_seq,
    s.total_sales,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales_after_returns,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    CASE WHEN s.total_sales = 0 THEN 0 ELSE s.total_discount / s.total_sales END AS discount_ratio,
    COALESCE(r.total_return_qty, 0) AS total_return_quantity,
    RANK() OVER (PARTITION BY s.sales_year, s.month_seq ORDER BY s.total_profit - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank,
    AVG(s.total_profit - COALESCE(r.total_return_loss, 0)) OVER (PARTITION BY s.category ORDER BY s.sales_year, s.month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_avg_profit
FROM sales_agg s
LEFT JOIN returns_agg r
   ON s.category = r.category AND s.sales_year = r.sales_year AND s.month_seq = r.month_seq
WHERE s.sales_year = 1999
ORDER BY s.sales_year, s.month_seq, profit_rank
LIMIT 100
