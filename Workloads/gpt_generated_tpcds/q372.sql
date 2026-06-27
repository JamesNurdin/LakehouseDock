WITH store_agg AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_loss
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN time_dim tdr
        ON sr.sr_return_time_sk = tdr.t_time_sk
    WHERE td.t_hour = 10
    GROUP BY i.i_brand, i.i_category
),
catalog_agg AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_loss
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN time_dim tdr
        ON cr.cr_returned_time_sk = tdr.t_time_sk
    WHERE td.t_hour = 10
    GROUP BY i.i_brand, i.i_category
),
web_agg AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_loss
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN time_dim tdr
        ON wr.wr_returned_time_sk = tdr.t_time_sk
    WHERE td.t_hour = 10
    GROUP BY i.i_brand, i.i_category
)
SELECT
    COALESCE(s.brand, c.brand, w.brand) AS brand,
    COALESCE(s.category, c.category, w.category) AS category,
    COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0)
        - (COALESCE(s.store_loss, 0) + COALESCE(c.catalog_loss, 0) + COALESCE(w.web_loss, 0)) AS net_contribution
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.brand = c.brand AND s.category = c.category
FULL OUTER JOIN web_agg w
    ON COALESCE(s.brand, c.brand) = w.brand
    AND COALESCE(s.category, c.category) = w.category
ORDER BY net_contribution DESC
LIMIT 10
