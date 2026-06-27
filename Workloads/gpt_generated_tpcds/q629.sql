WITH sales_union AS (
    -- Store sales per month
    SELECT
        d.d_year      AS d_year,
        d.d_moy       AS d_moy,
        'store'       AS channel,
        ss.ss_net_paid   AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk

    UNION ALL

    -- Web sales per month
    SELECT
        d.d_year,
        d.d_moy,
        'web',
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk

    UNION ALL

    -- Catalog sales per month
    SELECT
        d.d_year,
        d.d_moy,
        'catalog',
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk

    UNION ALL

    -- Catalog returns (treated as negative sales)
    SELECT
        d.d_year,
        d.d_moy,
        'catalog_return',
        -cr.cr_return_amount,
        -cr.cr_net_loss,
        cr.cr_refunded_customer_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
)
SELECT
    d_year,
    d_moy               AS month,
    channel,
    SUM(net_paid)       AS total_net_paid,
    SUM(net_profit)     AS total_net_profit,
    COUNT(DISTINCT customer_sk) AS unique_customers
FROM sales_union
GROUP BY d_year, d_moy, channel
ORDER BY d_year, d_moy, channel
