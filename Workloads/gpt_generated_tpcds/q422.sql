WITH sales_agg AS (
    SELECT
        da.d_year AS year,
        ca.ca_state AS state,
        SUM(cs.cs_net_paid) AS total_sales_net_paid,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    JOIN date_dim da ON cs.cs_sold_date_sk = da.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    GROUP BY da.d_year, ca.ca_state
),
catalog_returns_agg AS (
    SELECT
        da.d_year AS year,
        ca.ca_state AS state,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim da ON cr.cr_returned_date_sk = da.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY da.d_year, ca.ca_state
),
store_returns_agg AS (
    SELECT
        da.d_year AS year,
        ca.ca_state AS state,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN date_dim da ON sr.sr_returned_date_sk = da.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY da.d_year, ca.ca_state
),
web_returns_agg AS (
    SELECT
        da.d_year AS year,
        ca.ca_state AS state,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim da ON wr.wr_returned_date_sk = da.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY da.d_year, ca.ca_state
)
SELECT
    s.year,
    s.state,
    s.total_sales_net_paid,
    s.total_sales_net_profit,
    s.order_count,
    COALESCE(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    COALESCE(cr.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(sr.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(wr.total_web_return_loss, 0) AS total_web_return_loss,
    COALESCE(wr.web_return_cnt, 0) AS web_return_cnt,
    (s.total_sales_net_profit
        - COALESCE(cr.total_catalog_return_loss, 0)
        - COALESCE(sr.total_store_return_loss, 0)
        - COALESCE(wr.total_web_return_loss, 0)
    ) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN catalog_returns_agg cr ON s.year = cr.year AND s.state = cr.state
LEFT JOIN store_returns_agg sr ON s.year = sr.year AND s.state = sr.state
LEFT JOIN web_returns_agg wr ON s.year = wr.year AND s.state = wr.state
ORDER BY s.year, s.state
