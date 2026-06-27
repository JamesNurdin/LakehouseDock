WITH store_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
web_returns_agg AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        SUM(wr.wr_return_amt) AS web_return_amt,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    COALESCE(s.d_year, c.d_year, w.d_year) AS year,
    COALESCE(s.d_month_seq, c.d_month_seq, w.d_month_seq) AS month_seq,
    s.store_net_paid,
    s.store_net_profit,
    s.store_sales_cnt,
    c.catalog_net_paid,
    c.catalog_net_profit,
    c.catalog_sales_cnt,
    w.web_return_amt,
    w.web_net_loss,
    w.web_return_cnt,
    (COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0) - COALESCE(w.web_return_amt, 0)) AS total_net_paid_excluding_returns,
    (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) - COALESCE(w.web_net_loss, 0)) AS total_net_profit_excluding_returns
FROM store_sales_agg s
FULL OUTER JOIN catalog_sales_agg c
    ON s.d_year = c.d_year
   AND s.d_month_seq = c.d_month_seq
FULL OUTER JOIN web_returns_agg w
    ON COALESCE(s.d_year, c.d_year) = w.d_year
   AND COALESCE(s.d_month_seq, c.d_month_seq) = w.d_month_seq
ORDER BY year, month_seq
