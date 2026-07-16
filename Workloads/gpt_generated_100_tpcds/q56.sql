WITH
    store_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(ss.ss_net_profit) AS store_net_profit,
            SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss
        FROM store_sales ss
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
           AND ss.ss_item_sk = sr.sr_item_sk
        GROUP BY d.d_year, i.i_category
    ),
    catalog_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(cs.cs_net_profit) AS catalog_net_profit,
            SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_net_loss
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_order_number = cr.cr_order_number
           AND cs.cs_item_sk = cr.cr_item_sk
        GROUP BY d.d_year, i.i_category
    ),
    web_agg AS (
        SELECT
            d.d_year AS year,
            i.i_category AS category,
            SUM(ws.ws_net_profit) AS web_net_profit,
            SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss
        FROM web_sales ws
        JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
           AND ws.ws_item_sk = wr.wr_item_sk
        GROUP BY d.d_year, i.i_category
    )
SELECT
    COALESCE(s.year, c.year, w.year) AS year,
    COALESCE(s.category, c.category, w.category) AS category,
    COALESCE(s.store_net_profit, 0) - COALESCE(s.store_net_loss, 0) +
    COALESCE(c.catalog_net_profit, 0) - COALESCE(c.catalog_net_loss, 0) +
    COALESCE(w.web_net_profit, 0) - COALESCE(w.web_net_loss, 0) AS total_net_profit
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.year = c.year AND s.category = c.category
FULL OUTER JOIN web_agg w
    ON COALESCE(s.year, c.year) = w.year
   AND COALESCE(s.category, c.category) = w.category
ORDER BY total_net_profit DESC
LIMIT 20
