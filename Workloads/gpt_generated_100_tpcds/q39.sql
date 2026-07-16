WITH
    store_sales_agg AS (
        SELECT
            td.t_hour,
            SUM(ss.ss_net_paid) AS store_sales_net_paid,
            SUM(ss.ss_net_profit) AS store_sales_net_profit,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions
        FROM time_dim td
        JOIN store_sales ss
            ON ss.ss_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    store_returns_agg AS (
        SELECT
            td.t_hour,
            SUM(sr.sr_return_amt) AS store_return_amount,
            SUM(sr.sr_net_loss) AS store_return_net_loss,
            COUNT(*) AS store_return_count
        FROM time_dim td
        JOIN store_returns sr
            ON sr.sr_return_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    catalog_sales_agg AS (
        SELECT
            td.t_hour,
            SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
            SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
            COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions
        FROM time_dim td
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    web_sales_agg AS (
        SELECT
            td.t_hour,
            SUM(ws.ws_net_paid) AS web_sales_net_paid,
            SUM(ws.ws_net_profit) AS web_sales_net_profit,
            COUNT(DISTINCT ws.ws_order_number) AS web_transactions
        FROM time_dim td
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    )
SELECT
    ss.t_hour,
    ss.store_sales_net_paid,
    ss.store_sales_net_profit,
    sr.store_return_amount,
    sr.store_return_net_loss,
    cs.catalog_sales_net_paid,
    cs.catalog_sales_net_profit,
    ws.web_sales_net_paid,
    ws.web_sales_net_profit,
    (ss.store_sales_net_profit - COALESCE(sr.store_return_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (ss.store_sales_net_profit - COALESCE(sr.store_return_net_loss, 0)) DESC) AS profit_rank
FROM store_sales_agg ss
LEFT JOIN store_returns_agg sr
    ON ss.t_hour = sr.t_hour
LEFT JOIN catalog_sales_agg cs
    ON ss.t_hour = cs.t_hour
LEFT JOIN web_sales_agg ws
    ON ss.t_hour = ws.t_hour
ORDER BY ss.t_hour
