WITH sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number = 3
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY cs.cs_item_sk, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_return_amount) AS total_cr_returns,
        SUM(cr.cr_net_loss) AS total_cr_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number = 3
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY cr.cr_item_sk, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt_inc_tax) AS total_sr_returns,
        SUM(sr.sr_net_loss) AS total_sr_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY sr.sr_item_sk, d.d_year, d.d_month_seq
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    COALESCE(cr.total_cr_returns, 0) + COALESCE(sr.total_sr_returns, 0) AS total_returns,
    s.total_sales - (COALESCE(cr.total_cr_returns, 0) + COALESCE(sr.total_sr_returns, 0)) AS net_sales,
    s.total_profit - (COALESCE(cr.total_cr_loss, 0) + COALESCE(sr.total_sr_loss, 0)) AS net_profit,
    s.orders
FROM sales_agg s
LEFT JOIN catalog_returns_agg cr
    ON s.item_sk = cr.item_sk
   AND s.d_year = cr.d_year
   AND s.d_month_seq = cr.d_month_seq
LEFT JOIN store_returns_agg sr
    ON s.item_sk = sr.item_sk
   AND s.d_year = sr.d_year
   AND s.d_month_seq = sr.d_month_seq
JOIN item i
    ON s.item_sk = i.i_item_sk
ORDER BY net_profit DESC
LIMIT 10
