WITH months AS (
    SELECT DISTINCT d_year, d_month_seq
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
store_sales_agg AS (
    SELECT d_sold.d_year,
           d_sold.d_month_seq,
           sum(ss_net_paid) AS store_sales_net_paid,
           sum(ss_net_profit) AS store_sales_net_profit,
           count(distinct ss_customer_sk) AS store_sales_customers,
           count(*) AS store_sales_transactions
    FROM store_sales
    JOIN date_dim d_sold
      ON store_sales.ss_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_sold.d_year, d_sold.d_month_seq
),
store_returns_agg AS (
    SELECT d_ret.d_year,
           d_ret.d_month_seq,
           sum(sr_net_loss) AS store_returns_net_loss,
           count(*) AS store_returns_transactions
    FROM store_returns
    JOIN date_dim d_ret
      ON store_returns.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_ret.d_year, d_ret.d_month_seq
),
catalog_sales_agg AS (
    SELECT d_sold.d_year,
           d_sold.d_month_seq,
           sum(cs_net_paid) AS catalog_sales_net_paid,
           sum(cs_net_profit) AS catalog_sales_net_profit,
           count(distinct cs_bill_customer_sk) AS catalog_sales_customers,
           count(*) AS catalog_sales_transactions
    FROM catalog_sales
    JOIN date_dim d_sold
      ON catalog_sales.cs_sold_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_sold.d_year, d_sold.d_month_seq
),
catalog_returns_agg AS (
    SELECT d_ret.d_year,
           d_ret.d_month_seq,
           sum(cr_net_loss) AS catalog_returns_net_loss,
           count(*) AS catalog_returns_transactions
    FROM catalog_returns
    JOIN date_dim d_ret
      ON catalog_returns.cr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_ret.d_year, d_ret.d_month_seq
),
web_returns_agg AS (
    SELECT d_ret.d_year,
           d_ret.d_month_seq,
           sum(wr_net_loss) AS web_returns_net_loss,
           count(*) AS web_returns_transactions
    FROM web_returns
    JOIN date_dim d_ret
      ON web_returns.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d_ret.d_year, d_ret.d_month_seq
)
SELECT
    COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, wr.d_year) AS year,
    COALESCE(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, wr.d_month_seq) AS month_seq,
    ss.store_sales_net_paid,
    ss.store_sales_net_profit,
    ss.store_sales_customers,
    ss.store_sales_transactions,
    sr.store_returns_net_loss,
    sr.store_returns_transactions,
    cs.catalog_sales_net_paid,
    cs.catalog_sales_net_profit,
    cs.catalog_sales_customers,
    cs.catalog_sales_transactions,
    cr.catalog_returns_net_loss,
    cr.catalog_returns_transactions,
    wr.web_returns_net_loss,
    wr.web_returns_transactions,
    -- Net profit after accounting for all returns
    COALESCE(ss.store_sales_net_profit, 0)
    + COALESCE(cs.catalog_sales_net_profit, 0)
    - COALESCE(sr.store_returns_net_loss, 0)
    - COALESCE(cr.catalog_returns_net_loss, 0)
    - COALESCE(wr.web_returns_net_loss, 0) AS total_net_profit_after_returns
FROM months m
LEFT JOIN store_sales_agg ss
  ON ss.d_year = m.d_year AND ss.d_month_seq = m.d_month_seq
LEFT JOIN store_returns_agg sr
  ON sr.d_year = m.d_year AND sr.d_month_seq = m.d_month_seq
LEFT JOIN catalog_sales_agg cs
  ON cs.d_year = m.d_year AND cs.d_month_seq = m.d_month_seq
LEFT JOIN catalog_returns_agg cr
  ON cr.d_year = m.d_year AND cr.d_month_seq = m.d_month_seq
LEFT JOIN web_returns_agg wr
  ON wr.d_year = m.d_year AND wr.d_month_seq = m.d_month_seq
ORDER BY year, month_seq
