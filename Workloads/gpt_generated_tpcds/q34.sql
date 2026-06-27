WITH cat_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
cat_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
store_sales_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
web_returns_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    COALESCE(cat_sales.d_year, cat_returns.d_year, store_sales_monthly.d_year, web_returns_monthly.d_year) AS year,
    COALESCE(cat_sales.d_month_seq, cat_returns.d_month_seq, store_sales_monthly.d_month_seq, web_returns_monthly.d_month_seq) AS month_seq,
    cat_sales.catalog_net_paid,
    cat_sales.catalog_net_profit,
    cat_returns.catalog_return_loss,
    store_sales_monthly.store_net_paid,
    store_sales_monthly.store_net_profit,
    web_returns_monthly.web_return_loss,
    (COALESCE(cat_sales.catalog_net_profit, 0) + COALESCE(store_sales_monthly.store_net_profit, 0) - COALESCE(cat_returns.catalog_return_loss, 0) - COALESCE(web_returns_monthly.web_return_loss, 0)) AS total_net_profit
FROM cat_sales
FULL OUTER JOIN cat_returns
    ON cat_sales.d_year = cat_returns.d_year AND cat_sales.d_month_seq = cat_returns.d_month_seq
FULL OUTER JOIN store_sales_monthly
    ON COALESCE(cat_sales.d_year, cat_returns.d_year) = store_sales_monthly.d_year
   AND COALESCE(cat_sales.d_month_seq, cat_returns.d_month_seq) = store_sales_monthly.d_month_seq
FULL OUTER JOIN web_returns_monthly
    ON COALESCE(cat_sales.d_year, cat_returns.d_year, store_sales_monthly.d_year) = web_returns_monthly.d_year
   AND COALESCE(cat_sales.d_month_seq, cat_returns.d_month_seq, store_sales_monthly.d_month_seq) = web_returns_monthly.d_month_seq
ORDER BY year, month_seq
