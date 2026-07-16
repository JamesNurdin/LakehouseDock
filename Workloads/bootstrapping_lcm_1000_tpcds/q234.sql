WITH store_return_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_closed.d_year AS store_closed_year,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_closed.d_year
),
catalog_return_summary AS (
    SELECT
        d_cr.d_year,
        d_cr.d_month_seq,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    GROUP BY d_cr.d_year, d_cr.d_month_seq
),
web_sales_summary AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        SUM(ws.ws_net_profit) AS total_web_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_ext_ship_cost) AS total_web_ship_cost,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month_seq
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_year,
        d_ship.d_month_seq
)
SELECT
    srs.s_store_id,
    srs.s_store_name,
    srs.d_year AS return_year,
    srs.d_month_seq AS return_month,
    srs.store_closed_year,
    srs.total_store_net_loss,
    crs.total_catalog_net_loss,
    wss.total_web_net_profit,
    wss.total_web_sales,
    wss.total_web_ship_cost,
    wss.web_orders,
    wss.avg_sales_price,
    CASE
        WHEN (srs.total_store_net_loss + crs.total_catalog_net_loss) <> 0
        THEN wss.total_web_net_profit / (srs.total_store_net_loss + crs.total_catalog_net_loss)
        ELSE NULL
    END AS profit_to_loss_ratio,
    ROW_NUMBER() OVER (ORDER BY
        CASE
            WHEN (srs.total_store_net_loss + crs.total_catalog_net_loss) <> 0
            THEN wss.total_web_net_profit / (srs.total_store_net_loss + crs.total_catalog_net_loss)
            ELSE NULL
        END DESC) AS profit_loss_rank
FROM store_return_summary srs
JOIN catalog_return_summary crs
    ON srs.d_year = crs.d_year AND srs.d_month_seq = crs.d_month_seq
JOIN web_sales_summary wss
    ON srs.d_year = wss.d_year AND srs.d_month_seq = wss.d_month_seq
ORDER BY profit_to_loss_ratio DESC
LIMIT 100
