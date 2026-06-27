WITH store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.store_profit - s.store_loss AS net_store,
    c.catalog_profit - c.catalog_loss AS net_catalog,
    w.web_profit - w.web_loss AS net_web,
    (s.store_profit - s.store_loss) +
    (c.catalog_profit - c.catalog_loss) +
    (w.web_profit - w.web_loss) AS total_net_profit
FROM store_agg s
JOIN catalog_agg c
    ON s.d_year = c.d_year
    AND s.d_month_seq = c.d_month_seq
    AND s.i_category = c.i_category
JOIN web_agg w
    ON s.d_year = w.d_year
    AND s.d_month_seq = w.d_month_seq
    AND s.i_category = w.i_category
WHERE s.d_year = 2001
ORDER BY total_net_profit DESC
LIMIT 10
