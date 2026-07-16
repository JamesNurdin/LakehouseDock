WITH cr_agg AS (
    SELECT
        cr_returned_date_sk,
        SUM(cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
sr_agg AS (
    SELECT
        sr_returned_date_sk,
        sr_store_sk,
        SUM(sr_net_loss) AS store_return_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_store_sk
),
ws_sold_agg AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_net_profit) AS web_sales_profit,
        COUNT(*) AS web_sales_cnt
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
ws_ship_agg AS (
    SELECT
        ws_ship_date_sk,
        SUM(ws_ext_ship_cost) AS ship_cost_total,
        COUNT(*) AS ship_cnt
    FROM web_sales
    GROUP BY ws_ship_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_return.d_year,
    d_return.d_month_seq,
    COALESCE(cr_agg.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(sr_agg.store_return_net_loss, 0) AS store_return_net_loss,
    COALESCE(ws_sold_agg.web_sales_profit, 0) AS web_sales_profit,
    COALESCE(ws_ship_agg.ship_cost_total, 0) AS total_ship_cost,
    COALESCE(cr_agg.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(sr_agg.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(ws_sold_agg.web_sales_cnt, 0) AS web_sales_cnt,
    COALESCE(ws_ship_agg.ship_cnt, 0) AS ship_cnt,
    d_closed.d_current_month AS store_closed_month,
    d_ship.d_current_month AS ship_month
FROM store s
JOIN sr_agg
    ON sr_agg.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr_agg.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN cr_agg
    ON cr_agg.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN ws_sold_agg
    ON ws_sold_agg.ws_sold_date_sk = d_return.d_date_sk
LEFT JOIN ws_ship_agg
    ON ws_ship_agg.ws_ship_date_sk = d_return.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_ship
    ON ws_ship_agg.ws_ship_date_sk = d_ship.d_date_sk
WHERE d_return.d_year = 2001
ORDER BY s.s_store_id, d_return.d_year, d_return.d_month_seq
LIMIT 100
