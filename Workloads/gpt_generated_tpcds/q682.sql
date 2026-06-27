WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(cr.cr_return_amt_inc_tax) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
)
SELECT
    COALESCE(s.year, sr.year, c.year, cr.year, w.year, wr.year) AS year,
    COALESCE(s.category, sr.category, c.category, cr.category, w.category, wr.category) AS category,
    COALESCE(s.store_sales, 0) AS store_sales,
    COALESCE(s.store_profit, 0) AS store_profit,
    COALESCE(sr.store_return_amount, 0) AS store_return_amount,
    COALESCE(sr.store_return_loss, 0) AS store_return_loss,
    COALESCE(c.catalog_sales, 0) AS catalog_sales,
    COALESCE(c.catalog_profit, 0) AS catalog_profit,
    COALESCE(cr.catalog_return_amount, 0) AS catalog_return_amount,
    COALESCE(cr.catalog_return_loss, 0) AS catalog_return_loss,
    COALESCE(w.web_sales, 0) AS web_sales,
    COALESCE(w.web_profit, 0) AS web_profit,
    COALESCE(wr.web_return_amount, 0) AS web_return_amount,
    COALESCE(wr.web_return_loss, 0) AS web_return_loss,
    COALESCE(s.store_customers, 0) + COALESCE(c.catalog_customers, 0) + COALESCE(w.web_customers, 0) AS total_customers
FROM store_sales_agg s
FULL OUTER JOIN store_returns_agg sr
    ON s.year = sr.year AND s.category = sr.category
FULL OUTER JOIN catalog_sales_agg c
    ON COALESCE(s.year, sr.year) = c.year
   AND COALESCE(s.category, sr.category) = c.category
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(s.year, sr.year, c.year) = cr.year
   AND COALESCE(s.category, sr.category, c.category) = cr.category
FULL OUTER JOIN web_sales_agg w
    ON COALESCE(s.year, sr.year, c.year, cr.year) = w.year
   AND COALESCE(s.category, sr.category, c.category, cr.category) = w.category
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(s.year, sr.year, c.year, cr.year, w.year) = wr.year
   AND COALESCE(s.category, sr.category, c.category, cr.category, w.category) = wr.category
WHERE COALESCE(s.year, sr.year, c.year, cr.year, w.year, wr.year) >= 2000
ORDER BY year, category
