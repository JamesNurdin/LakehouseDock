/*
  Analytical query: Net profit by product category & brand for 2022, after accounting for store and catalog returns.
  Shows monthly totals, the net profit after returns, and a cumulative net‑profit running total.
*/
WITH web_sales_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_category, i.i_brand, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_category, i.i_brand, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_category, i.i_brand, d.d_year, d.d_month_seq
)
SELECT
    t.i_category,
    t.i_brand,
    t.d_year,
    t.d_month_seq,
    t.total_net_profit,
    t.total_store_return_loss,
    t.total_catalog_return_loss,
    t.net_profit_after_returns,
    SUM(t.net_profit_after_returns) OVER (
        PARTITION BY t.i_category, t.i_brand
        ORDER BY t.d_year, t.d_month_seq
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_net_profit
FROM (
    SELECT
        ws.i_category,
        ws.i_brand,
        ws.d_year,
        ws.d_month_seq,
        ws.total_net_profit,
        COALESCE(sr.total_store_return_loss, 0) AS total_store_return_loss,
        COALESCE(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
        ws.total_net_profit - COALESCE(sr.total_store_return_loss, 0) - COALESCE(cr.total_catalog_return_loss, 0) AS net_profit_after_returns
    FROM web_sales_agg ws
    LEFT JOIN store_returns_agg sr
        ON ws.i_category = sr.i_category
        AND ws.i_brand = sr.i_brand
        AND ws.d_year = sr.d_year
        AND ws.d_month_seq = sr.d_month_seq
    LEFT JOIN catalog_returns_agg cr
        ON ws.i_category = cr.i_category
        AND ws.i_brand = cr.i_brand
        AND ws.d_year = cr.d_year
        AND ws.d_month_seq = cr.d_month_seq
) t
ORDER BY t.net_profit_after_returns DESC
LIMIT 20
