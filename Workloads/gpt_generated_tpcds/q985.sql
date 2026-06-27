WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        d_sales.d_year AS year,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, d_sales.d_year
),
store_returns_agg AS (
    SELECT
        c.c_customer_id,
        d_return.d_year AS year,
        SUM(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, d_return.d_year
),
catalog_returns_agg AS (
    SELECT
        c.c_customer_id,
        d_cat.d_year AS year,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d_cat
        ON cr.cr_returned_date_sk = d_cat.d_date_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, d_cat.d_year
),
web_returns_agg AS (
    SELECT
        c.c_customer_id,
        d_web.d_year AS year,
        SUM(wr.wr_net_loss) AS total_web_return_loss
    FROM web_returns wr
    JOIN date_dim d_web
        ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id, d_web.d_year
)
SELECT
    s.c_customer_id,
    s.year,
    s.total_sales,
    s.total_profit,
    s.total_discount,
    CASE
        WHEN s.total_sales > 0 THEN s.total_discount / s.total_sales
        ELSE 0
    END AS discount_rate,
    COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    s.total_profit
        - COALESCE(sr.total_store_return_loss, 0)
        - COALESCE(cr.total_catalog_return_loss, 0)
        - COALESCE(wr.total_web_return_loss, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN store_returns_agg sr
    ON s.c_customer_id = sr.c_customer_id AND s.year = sr.year
LEFT JOIN catalog_returns_agg cr
    ON s.c_customer_id = cr.c_customer_id AND s.year = cr.year
LEFT JOIN web_returns_agg wr
    ON s.c_customer_id = wr.c_customer_id AND s.year = wr.year
WHERE s.year = 2001
ORDER BY net_profit_after_returns DESC
LIMIT 100
