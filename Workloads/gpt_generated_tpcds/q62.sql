WITH web_sales_agg AS (
    SELECT
        date_dim.d_year,
        date_dim.d_moy,
        item.i_category,
        SUM(web_sales.ws_net_profit) AS web_net_profit,
        SUM(web_sales.ws_net_paid)   AS web_net_paid
    FROM web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN item     ON web_sales.ws_item_sk      = item.i_item_sk
    WHERE date_dim.d_date >= DATE '2021-01-01'
      AND date_dim.d_date <= DATE '2021-12-31'
    GROUP BY date_dim.d_year, date_dim.d_moy, item.i_category
),
store_sales_agg AS (
    SELECT
        date_dim.d_year,
        date_dim.d_moy,
        item.i_category,
        SUM(store_sales.ss_net_profit) AS store_net_profit,
        SUM(store_sales.ss_net_paid)   AS store_net_paid
    FROM store_sales
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    JOIN item     ON store_sales.ss_item_sk      = item.i_item_sk
    WHERE date_dim.d_date >= DATE '2021-01-01'
      AND date_dim.d_date <= DATE '2021-12-31'
    GROUP BY date_dim.d_year, date_dim.d_moy, item.i_category
),
web_returns_agg AS (
    SELECT
        date_dim.d_year,
        date_dim.d_moy,
        item.i_category,
        SUM(web_returns.wr_net_loss)      AS returns_net_loss,
        SUM(web_returns.wr_refunded_cash) AS returns_refunded_cash
    FROM web_returns
    JOIN date_dim ON web_returns.wr_returned_date_sk = date_dim.d_date_sk
    JOIN item     ON web_returns.wr_item_sk          = item.i_item_sk
    WHERE date_dim.d_date >= DATE '2021-01-01'
      AND date_dim.d_date <= DATE '2021-12-31'
    GROUP BY date_dim.d_year, date_dim.d_moy, item.i_category
)
SELECT
    COALESCE(ws_agg.d_year, ss_agg.d_year, wr_agg.d_year) AS year,
    COALESCE(ws_agg.d_moy, ss_agg.d_moy, wr_agg.d_moy)    AS month,
    COALESCE(ws_agg.i_category, ss_agg.i_category, wr_agg.i_category) AS category,
    COALESCE(ws_agg.web_net_profit, 0)   AS web_net_profit,
    COALESCE(ss_agg.store_net_profit, 0) AS store_net_profit,
    COALESCE(wr_agg.returns_net_loss, 0) AS returns_net_loss,
    COALESCE(ws_agg.web_net_profit, 0) - COALESCE(wr_agg.returns_net_loss, 0) AS net_profit_after_returns
FROM web_sales_agg   ws_agg
FULL OUTER JOIN store_sales_agg ss_agg
    ON ws_agg.d_year = ss_agg.d_year
   AND ws_agg.d_moy  = ss_agg.d_moy
   AND ws_agg.i_category = ss_agg.i_category
FULL OUTER JOIN web_returns_agg wr_agg
    ON COALESCE(ws_agg.d_year, ss_agg.d_year) = wr_agg.d_year
   AND COALESCE(ws_agg.d_moy, ss_agg.d_moy)   = wr_agg.d_moy
   AND COALESCE(ws_agg.i_category, ss_agg.i_category) = wr_agg.i_category
ORDER BY year, month, category
