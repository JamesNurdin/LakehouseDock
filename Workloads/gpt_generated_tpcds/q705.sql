WITH
    store_sales_agg AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            SUM(ss.ss_net_profit) AS store_net_profit,
            SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss
        FROM store_sales ss
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
            AND ss.ss_item_sk = sr.sr_item_sk
            AND sr.sr_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, c.c_customer_id
    ),
    catalog_sales_agg AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            SUM(cs.cs_net_profit) AS catalog_net_profit,
            SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_net_loss
        FROM catalog_sales cs
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_item_sk = cr.cr_item_sk
            AND cs.cs_order_number = cr.cr_order_number
            AND cr.cr_refunded_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, c.c_customer_id
    ),
    web_sales_agg AS (
        SELECT
            c.c_customer_sk,
            c.c_customer_id,
            SUM(ws.ws_net_profit) AS web_net_profit,
            SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss
        FROM web_sales ws
        JOIN customer c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN web_returns wr
            ON ws.ws_item_sk = wr.wr_item_sk
            AND ws.ws_order_number = wr.wr_order_number
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
        GROUP BY c.c_customer_sk, c.c_customer_id
    )
SELECT
    COALESCE(s.c_customer_sk, ca.c_customer_sk, w.c_customer_sk) AS customer_sk,
    COALESCE(s.c_customer_id, ca.c_customer_id, w.c_customer_id) AS customer_id,
    COALESCE(s.store_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
    COALESCE(s.store_net_loss, 0) + COALESCE(ca.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
    (COALESCE(s.store_net_profit, 0) + COALESCE(ca.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0))
    - (COALESCE(s.store_net_loss, 0) + COALESCE(ca.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0)) AS net_profit_after_returns
FROM store_sales_agg s
FULL OUTER JOIN catalog_sales_agg ca
    ON s.c_customer_sk = ca.c_customer_sk
FULL OUTER JOIN web_sales_agg w
    ON COALESCE(s.c_customer_sk, ca.c_customer_sk) = w.c_customer_sk
ORDER BY net_profit_after_returns DESC
LIMIT 10
