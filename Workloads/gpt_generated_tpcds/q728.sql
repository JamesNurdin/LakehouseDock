WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sum(cs.cs_net_paid) AS total_sales_net_paid,
        sum(cs.cs_net_profit) AS total_sales_net_profit,
        count(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sum(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sum(sr.sr_net_loss) AS store_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_ret AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        sum(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_sales_net_paid,
    s.total_sales_net_profit,
    coalesce(cr.catalog_return_loss, 0) AS catalog_return_loss,
    coalesce(sr.store_return_loss, 0) AS store_return_loss,
    coalesce(wr.web_return_loss, 0) AS web_return_loss,
    s.total_sales_net_paid - (coalesce(cr.catalog_return_loss, 0) + coalesce(sr.store_return_loss, 0) + coalesce(wr.web_return_loss, 0)) AS net_revenue,
    s.total_sales_net_profit - (coalesce(cr.catalog_return_loss, 0) + coalesce(sr.store_return_loss, 0) + coalesce(wr.web_return_loss, 0)) AS net_profit,
    s.distinct_customers
FROM sales s
LEFT JOIN catalog_ret cr
    ON s.d_year = cr.d_year
    AND s.d_month_seq = cr.d_month_seq
    AND s.i_category = cr.i_category
LEFT JOIN store_ret sr
    ON s.d_year = sr.d_year
    AND s.d_month_seq = sr.d_month_seq
    AND s.i_category = sr.i_category
LEFT JOIN web_ret wr
    ON s.d_year = wr.d_year
    AND s.d_month_seq = wr.d_month_seq
    AND s.i_category = wr.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
