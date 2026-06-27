WITH
    store_sales_agg AS (
        SELECT
            date_trunc('month', d_sales.d_date) AS month,
            'store' AS channel,
            SUM(ss_net_paid) AS net_paid
        FROM store_sales
        JOIN date_dim d_sales ON store_sales.ss_sold_date_sk = d_sales.d_date_sk
        JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
        JOIN customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND d_sales.d_year = 2001
        GROUP BY date_trunc('month', d_sales.d_date), 'store'
    ),
    store_returns_agg AS (
        SELECT
            date_trunc('month', d_sales.d_date) AS month,
            'store' AS channel,
            SUM(sr_net_loss) AS net_loss
        FROM store_returns
        JOIN store_sales ON store_returns.sr_ticket_number = store_sales.ss_ticket_number
            AND store_returns.sr_item_sk = store_sales.ss_item_sk
        JOIN date_dim d_sales ON store_sales.ss_sold_date_sk = d_sales.d_date_sk
        JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
        JOIN customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND d_sales.d_year = 2001
        GROUP BY date_trunc('month', d_sales.d_date), 'store'
    ),
    catalog_sales_agg AS (
        SELECT
            date_trunc('month', d_sales.d_date) AS month,
            'catalog' AS channel,
            SUM(cs_net_paid) AS net_paid
        FROM catalog_sales
        JOIN date_dim d_sales ON catalog_sales.cs_sold_date_sk = d_sales.d_date_sk
        JOIN customer ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
        JOIN customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND d_sales.d_year = 2001
        GROUP BY date_trunc('month', d_sales.d_date), 'catalog'
    ),
    catalog_returns_agg AS (
        SELECT
            date_trunc('month', d_sales.d_date) AS month,
            'catalog' AS channel,
            SUM(cr_net_loss) AS net_loss
        FROM catalog_returns
        JOIN catalog_sales ON catalog_returns.cr_order_number = catalog_sales.cs_order_number
            AND catalog_returns.cr_item_sk = catalog_sales.cs_item_sk
        JOIN date_dim d_sales ON catalog_sales.cs_sold_date_sk = d_sales.d_date_sk
        JOIN customer ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
        JOIN customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND d_sales.d_year = 2001
        GROUP BY date_trunc('month', d_sales.d_date), 'catalog'
    ),
    web_sales_agg AS (
        SELECT
            date_trunc('month', d_sales.d_date) AS month,
            'web' AS channel,
            SUM(ws_net_paid) AS net_paid
        FROM web_sales
        JOIN date_dim d_sales ON web_sales.ws_sold_date_sk = d_sales.d_date_sk
        JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
        JOIN customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND d_sales.d_year = 2001
        GROUP BY date_trunc('month', d_sales.d_date), 'web'
    ),
    web_returns_agg AS (
        SELECT
            date_trunc('month', d_sales.d_date) AS month,
            'web' AS channel,
            SUM(wr_net_loss) AS net_loss
        FROM web_returns
        JOIN web_sales ON web_returns.wr_order_number = web_sales.ws_order_number
            AND web_returns.wr_item_sk = web_sales.ws_item_sk
        JOIN date_dim d_sales ON web_sales.ws_sold_date_sk = d_sales.d_date_sk
        JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
        JOIN customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND d_sales.d_year = 2001
        GROUP BY date_trunc('month', d_sales.d_date), 'web'
    ),
    combined AS (
        SELECT month, channel, net_paid, CAST(0 AS decimal(7,2)) AS net_loss FROM store_sales_agg
        UNION ALL
        SELECT month, channel, CAST(0 AS decimal(7,2)) AS net_paid, net_loss FROM store_returns_agg
        UNION ALL
        SELECT month, channel, net_paid, CAST(0 AS decimal(7,2)) AS net_loss FROM catalog_sales_agg
        UNION ALL
        SELECT month, channel, CAST(0 AS decimal(7,2)) AS net_paid, net_loss FROM catalog_returns_agg
        UNION ALL
        SELECT month, channel, net_paid, CAST(0 AS decimal(7,2)) AS net_loss FROM web_sales_agg
        UNION ALL
        SELECT month, channel, CAST(0 AS decimal(7,2)) AS net_paid, net_loss FROM web_returns_agg
    )
SELECT
    month,
    channel,
    SUM(net_paid) AS total_net_paid,
    SUM(net_loss) AS total_return_loss,
    SUM(net_paid) - SUM(net_loss) AS net_profit_adjusted
FROM combined
GROUP BY month, channel
ORDER BY net_profit_adjusted DESC
LIMIT 10
