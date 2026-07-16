WITH sales_base AS (
    SELECT d.d_date,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           i.i_category,
           i.i_category_id,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel,
           p.p_promo_name AS promo_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT d.d_date,
           ss.ss_sold_date_sk,
           ss.ss_item_sk,
           i.i_category,
           i.i_category_id,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           'store' AS channel,
           p.p_promo_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT d.d_date,
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           i.i_category,
           i.i_category_id,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web' AS channel,
           p.p_promo_name
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
returns_base AS (
    SELECT d.d_date,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           i.i_category,
           i.i_category_id,
           -cr.cr_return_quantity AS quantity,
           -cr.cr_return_amount AS net_paid,
           -cr.cr_net_loss AS net_profit,
           'catalog' AS channel,
           NULL AS promo_name
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT d.d_date,
           sr.sr_returned_date_sk,
           sr.sr_item_sk,
           i.i_category,
           i.i_category_id,
           -sr.sr_return_quantity,
           -sr.sr_return_amt,
           -sr.sr_net_loss,
           'store' AS channel,
           NULL
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT d.d_date,
           wr.wr_returned_date_sk,
           wr.wr_item_sk,
           i.i_category,
           i.i_category_id,
           -wr.wr_return_quantity,
           -wr.wr_return_amt,
           -wr.wr_net_loss,
           'web' AS channel,
           NULL
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
combined AS (
    SELECT * FROM sales_base
    UNION ALL
    SELECT * FROM returns_base
),
daily_agg AS (
    SELECT
        d_date,
        channel,
        i_category,
        promo_name,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit
    FROM combined
    GROUP BY d_date, channel, i_category, promo_name
)
SELECT
    d_date,
    channel,
    i_category,
    promo_name,
    total_quantity,
    total_net_paid,
    total_net_profit,
    ROUND(AVG(total_net_profit) OVER (PARTITION BY channel, i_category, promo_name ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS moving_avg_7d_profit
FROM daily_agg
ORDER BY d_date, channel, total_net_profit DESC
