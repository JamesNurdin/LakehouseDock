WITH
    sales_agg AS (
        SELECT
            ss.ss_store_sk AS store_sk,
            ss.ss_sold_date_sk AS date_sk,
            d.d_year,
            d.d_month_seq,
            SUM(ss.ss_net_profit) AS total_sales_profit,
            SUM(ss.ss_ext_sales_price) AS total_sales_amount,
            SUM(ss.ss_quantity) AS total_quantity_sold
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, d.d_year, d.d_month_seq
    ),
    catalog_ret_agg AS (
        SELECT
            cr.cr_returned_date_sk AS date_sk,
            SUM(cr.cr_net_loss) AS catalog_net_loss,
            SUM(cr.cr_return_amount) AS catalog_return_amount,
            COUNT(*) AS catalog_return_cnt
        FROM catalog_returns cr
        GROUP BY cr.cr_returned_date_sk
    ),
    web_ret_agg AS (
        SELECT
            wr.wr_returned_date_sk AS date_sk,
            SUM(wr.wr_net_loss) AS web_net_loss,
            SUM(wr.wr_return_amt) AS web_return_amount,
            COUNT(*) AS web_return_cnt
        FROM web_returns wr
        GROUP BY wr.wr_returned_date_sk
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq AS month_seq,
    s.s_state,
    s.s_city,
    COALESCE(sa.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(cr.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(wr.web_net_loss, 0) AS web_net_loss,
    COALESCE(sa.total_sales_profit, 0) - COALESCE(cr.catalog_net_loss, 0) - COALESCE(wr.web_net_loss, 0) AS net_profit_after_returns,
    COALESCE(cr.catalog_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0) AS total_return_count,
    COALESCE(sa.total_quantity_sold, 0) AS total_quantity_sold,
    CASE
        WHEN COALESCE(sa.total_quantity_sold, 0) = 0 THEN 0
        ELSE (COALESCE(cr.catalog_return_cnt, 0) + COALESCE(wr.web_return_cnt, 0)) * 1.0 / COALESCE(sa.total_quantity_sold, 0)
    END AS return_rate,
    d_closure.d_year AS store_closed_year,
    d_closure.d_month_seq AS store_closed_month_seq
FROM date_dim d_sales
LEFT JOIN sales_agg sa ON sa.date_sk = d_sales.d_date_sk
LEFT JOIN catalog_ret_agg cr ON cr.date_sk = d_sales.d_date_sk
LEFT JOIN web_ret_agg wr ON wr.date_sk = d_sales.d_date_sk
LEFT JOIN store s ON s.s_store_sk = sa.store_sk
LEFT JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d_sales.d_year BETWEEN 2020 AND 2022
  AND s.s_store_id IS NOT NULL
ORDER BY s.s_store_id, d_sales.d_year, d_sales.d_month_seq
LIMIT 100
