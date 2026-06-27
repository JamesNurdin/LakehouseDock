WITH
    store_sales_agg AS (
        SELECT
            c.c_customer_sk,
            t.t_hour,
            SUM(ss.ss_net_paid) AS store_net_paid,
            0.0 AS store_net_loss,
            0.0 AS catalog_net_paid,
            0.0 AS catalog_net_loss,
            0.0 AS web_net_paid,
            0.0 AS web_net_loss
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, t.t_hour
    ),
    store_returns_agg AS (
        SELECT
            c.c_customer_sk,
            t.t_hour,
            0.0 AS store_net_paid,
            SUM(sr.sr_net_loss) AS store_net_loss,
            0.0 AS catalog_net_paid,
            0.0 AS catalog_net_loss,
            0.0 AS web_net_paid,
            0.0 AS web_net_loss
        FROM store_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, t.t_hour
    ),
    catalog_sales_agg AS (
        SELECT
            c.c_customer_sk,
            t.t_hour,
            0.0 AS store_net_paid,
            0.0 AS store_net_loss,
            SUM(cs.cs_net_paid) AS catalog_net_paid,
            0.0 AS catalog_net_loss,
            0.0 AS web_net_paid,
            0.0 AS web_net_loss
        FROM catalog_sales cs
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, t.t_hour
    ),
    catalog_returns_agg AS (
        SELECT
            c.c_customer_sk,
            t.t_hour,
            0.0 AS store_net_paid,
            0.0 AS store_net_loss,
            0.0 AS catalog_net_paid,
            SUM(cr.cr_net_loss) AS catalog_net_loss,
            0.0 AS web_net_paid,
            0.0 AS web_net_loss
        FROM catalog_returns cr
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, t.t_hour
    ),
    web_sales_agg AS (
        SELECT
            c.c_customer_sk,
            t.t_hour,
            0.0 AS store_net_paid,
            0.0 AS store_net_loss,
            0.0 AS catalog_net_paid,
            0.0 AS catalog_net_loss,
            SUM(ws.ws_net_paid) AS web_net_paid,
            0.0 AS web_net_loss
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, t.t_hour
    ),
    web_returns_agg AS (
        SELECT
            c.c_customer_sk,
            t.t_hour,
            0.0 AS store_net_paid,
            0.0 AS store_net_loss,
            0.0 AS catalog_net_paid,
            0.0 AS catalog_net_loss,
            0.0 AS web_net_paid,
            SUM(wr.wr_net_loss) AS web_net_loss
        FROM web_returns wr
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, t.t_hour
    ),
    combined AS (
        SELECT c_customer_sk, t_hour, store_net_paid, store_net_loss, catalog_net_paid, catalog_net_loss, web_net_paid, web_net_loss FROM store_sales_agg
        UNION ALL
        SELECT c_customer_sk, t_hour, store_net_paid, store_net_loss, catalog_net_paid, catalog_net_loss, web_net_paid, web_net_loss FROM store_returns_agg
        UNION ALL
        SELECT c_customer_sk, t_hour, store_net_paid, store_net_loss, catalog_net_paid, catalog_net_loss, web_net_paid, web_net_loss FROM catalog_sales_agg
        UNION ALL
        SELECT c_customer_sk, t_hour, store_net_paid, store_net_loss, catalog_net_paid, catalog_net_loss, web_net_paid, web_net_loss FROM catalog_returns_agg
        UNION ALL
        SELECT c_customer_sk, t_hour, store_net_paid, store_net_loss, catalog_net_paid, catalog_net_loss, web_net_paid, web_net_loss FROM web_sales_agg
        UNION ALL
        SELECT c_customer_sk, t_hour, store_net_paid, store_net_loss, catalog_net_paid, catalog_net_loss, web_net_paid, web_net_loss FROM web_returns_agg
    )
SELECT
    c.c_customer_id,
    combined.t_hour,
    SUM(combined.store_net_paid) + SUM(combined.catalog_net_paid) + SUM(combined.web_net_paid) AS total_net_paid,
    SUM(combined.store_net_loss) + SUM(combined.catalog_net_loss) + SUM(combined.web_net_loss) AS total_net_loss,
    SUM(combined.store_net_paid) + SUM(combined.catalog_net_paid) + SUM(combined.web_net_paid) -
    (SUM(combined.store_net_loss) + SUM(combined.catalog_net_loss) + SUM(combined.web_net_loss)) AS net_profit
FROM combined
JOIN customer c ON combined.c_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id, combined.t_hour
ORDER BY net_profit DESC
LIMIT 10
