WITH
    store_net AS (
        SELECT
            s.s_store_id,
            d.d_year,
            SUM(ss.ss_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0) AS store_net_profit
        FROM store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
           AND ss.ss_item_sk = sr.sr_item_sk
           AND sr.sr_store_sk = s.s_store_sk
           AND sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_id, d.d_year
    ),
    catalog_net AS (
        SELECT
            d.d_year,
            SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
           AND cs.cs_item_sk = cr.cr_item_sk
           AND cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year
    ),
    web_net AS (
        SELECT
            d.d_year,
            SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS web_net_profit
        FROM web_sales ws
        JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
           AND ws.ws_item_sk = wr.wr_item_sk
           AND wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year
    )
SELECT
    sn.s_store_id,
    sn.d_year,
    sn.store_net_profit,
    cn.catalog_net_profit,
    wn.web_net_profit,
    (sn.store_net_profit + cn.catalog_net_profit + wn.web_net_profit) AS total_net_profit
FROM store_net sn
JOIN catalog_net cn
    ON sn.d_year = cn.d_year
JOIN web_net wn
    ON sn.d_year = wn.d_year
ORDER BY total_net_profit DESC
LIMIT 20
