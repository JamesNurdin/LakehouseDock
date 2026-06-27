WITH combined AS (
    -- Store sales
    SELECT d.d_year,
           i.i_category,
           ss.ss_net_profit               AS net_profit,
           ss.ss_net_paid                 AS net_paid,
           ss.ss_ext_discount_amt         AS discount_amount,
           0.0                            AS net_loss
    FROM store_sales ss
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i       ON ss.ss_item_sk      = i.i_item_sk

    UNION ALL

    -- Catalog sales
    SELECT d.d_year,
           i.i_category,
           cs.cs_net_profit               AS net_profit,
           cs.cs_net_paid                 AS net_paid,
           cs.cs_ext_discount_amt         AS discount_amount,
           0.0                            AS net_loss
    FROM catalog_sales cs
    JOIN date_dim d   ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i       ON cs.cs_item_sk      = i.i_item_sk

    UNION ALL

    -- Web sales
    SELECT d.d_year,
           i.i_category,
           ws.ws_net_profit               AS net_profit,
           ws.ws_net_paid                 AS net_paid,
           ws.ws_ext_discount_amt         AS discount_amount,
           0.0                            AS net_loss
    FROM web_sales ws
    JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i       ON ws.ws_item_sk      = i.i_item_sk

    UNION ALL

    -- Catalog returns
    SELECT d.d_year,
           i.i_category,
           0.0                            AS net_profit,
           0.0                            AS net_paid,
           0.0                            AS discount_amount,
           cr.cr_net_loss                 AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d   ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i       ON cr.cr_item_sk         = i.i_item_sk

    UNION ALL

    -- Store returns
    SELECT d.d_year,
           i.i_category,
           0.0                            AS net_profit,
           0.0                            AS net_paid,
           0.0                            AS discount_amount,
           sr.sr_net_loss                 AS net_loss
    FROM store_returns sr
    JOIN date_dim d   ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i       ON sr.sr_item_sk          = i.i_item_sk

    UNION ALL

    -- Web returns
    SELECT d.d_year,
           i.i_category,
           0.0                            AS net_profit,
           0.0                            AS net_paid,
           0.0                            AS discount_amount,
           wr.wr_net_loss                 AS net_loss
    FROM web_returns wr
    JOIN date_dim d   ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i       ON wr.wr_item_sk          = i.i_item_sk
)
SELECT c.d_year,
       c.i_category,
       SUM(c.net_profit) - SUM(c.net_loss) AS net_profit_after_returns,
       SUM(c.net_paid)                     AS total_net_paid,
       SUM(c.discount_amount)              AS total_discount_amount,
       SUM(c.net_loss)                     AS total_returns_loss
FROM combined c
GROUP BY c.d_year, c.i_category
ORDER BY c.d_year, c.i_category
