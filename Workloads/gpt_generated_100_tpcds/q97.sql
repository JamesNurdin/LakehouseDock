WITH unified AS (
    -- Store sales (net profit and sales amount)
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_moy,
        ss.ss_ext_sales_price            AS store_sales_amount,
        CAST(0 AS decimal(7,2))          AS catalog_sales_amount,
        ss.ss_net_profit                 AS store_net_profit,
        CAST(0 AS decimal(7,2))          AS catalog_net_profit,
        CAST(0 AS decimal(7,2))          AS catalog_return_loss,
        CAST(0 AS decimal(7,2))          AS web_return_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Catalog sales (net profit and sales amount)
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_moy,
        CAST(0 AS decimal(7,2))          AS store_sales_amount,
        cs.cs_ext_sales_price            AS catalog_sales_amount,
        CAST(0 AS decimal(7,2))          AS store_net_profit,
        cs.cs_net_profit                 AS catalog_net_profit,
        CAST(0 AS decimal(7,2))          AS catalog_return_loss,
        CAST(0 AS decimal(7,2))          AS web_return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Catalog returns (net loss)
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_moy,
        CAST(0 AS decimal(7,2))          AS store_sales_amount,
        CAST(0 AS decimal(7,2))          AS catalog_sales_amount,
        CAST(0 AS decimal(7,2))          AS store_net_profit,
        CAST(0 AS decimal(7,2))          AS catalog_net_profit,
        cr.cr_net_loss                   AS catalog_return_loss,
        CAST(0 AS decimal(7,2))          AS web_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000

    UNION ALL

    -- Web returns (net loss)
    SELECT
        c.c_customer_id,
        d.d_year,
        d.d_moy,
        CAST(0 AS decimal(7,2))          AS store_sales_amount,
        CAST(0 AS decimal(7,2))          AS catalog_sales_amount,
        CAST(0 AS decimal(7,2))          AS store_net_profit,
        CAST(0 AS decimal(7,2))          AS catalog_net_profit,
        CAST(0 AS decimal(7,2))          AS catalog_return_loss,
        wr.wr_net_loss                   AS web_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000
)
SELECT
    u.c_customer_id,
    u.d_year,
    u.d_moy,
    sum(u.store_sales_amount)                                 AS store_sales_amount,
    sum(u.catalog_sales_amount)                               AS catalog_sales_amount,
    sum(u.store_net_profit) + sum(u.catalog_net_profit)      AS total_net_profit,
    sum(u.catalog_return_loss) + sum(u.web_return_loss)     AS total_return_loss,
    (sum(u.store_net_profit) + sum(u.catalog_net_profit) -
     sum(u.catalog_return_loss) - sum(u.web_return_loss))   AS net_profit_after_returns
FROM unified u
GROUP BY u.c_customer_id, u.d_year, u.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 100
