WITH
    -- Returns from the three channels, each tagged with the quarter of the return date
    store_ret AS (
        SELECT d.d_quarter_name AS quarter,
               sr.sr_net_loss      AS net_loss
        FROM   store_returns sr
        JOIN   date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    ),
    web_ret AS (
        SELECT d.d_quarter_name AS quarter,
               wr.wr_net_loss      AS net_loss
        FROM   web_returns wr
        JOIN   date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    ),
    catalog_ret AS (
        SELECT d.d_quarter_name AS quarter,
               cr.cr_net_loss      AS net_loss
        FROM   catalog_returns cr
        JOIN   date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    ),
    -- Union all return rows so we can aggregate them together
    all_returns AS (
        SELECT quarter, net_loss FROM store_ret
        UNION ALL
        SELECT quarter, net_loss FROM web_ret
        UNION ALL
        SELECT quarter, net_loss FROM catalog_ret
    ),
    -- Total net loss from returns, by quarter
    returns_agg AS (
        SELECT quarter,
               SUM(net_loss) AS total_return_net_loss
        FROM   all_returns
        GROUP BY quarter
    ),
    -- Web‑sales profit, broken out by promotion and quarter
    web_sales_promo AS (
        SELECT d.d_quarter_name        AS quarter,
               p.p_promo_name          AS promo_name,
               SUM(ws.ws_net_profit)   AS promo_net_profit
        FROM   web_sales ws
        JOIN   date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN   promotion p  ON ws.ws_promo_sk = p.p_promo_sk
        GROUP BY d.d_quarter_name, p.p_promo_name
    )
SELECT ws.quarter,
       ws.promo_name,
       ws.promo_net_profit,
       r.total_return_net_loss,
       (ws.promo_net_profit - r.total_return_net_loss) AS net_profit_after_returns
FROM   web_sales_promo ws
JOIN   returns_agg r ON ws.quarter = r.quarter
ORDER BY ws.quarter, ws.promo_name
