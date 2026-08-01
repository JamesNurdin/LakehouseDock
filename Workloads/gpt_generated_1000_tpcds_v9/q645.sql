WITH web_agg AS (
    SELECT
        'web' AS return_source,
        d_wr.d_date AS return_date,
        d_ws_sold.d_fy_year AS fiscal_year,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(p.p_cost) AS promo_cost,
        SUM(wr.wr_return_quantity) AS total_quantity
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    GROUP BY d_wr.d_date, d_ws_sold.d_fy_year
),
catalog_agg AS (
    SELECT
        'catalog' AS return_source,
        d_cr.d_date AS return_date,
        d_cr_fiscal.d_fy_year AS fiscal_year,
        SUM(cr.cr_net_loss) AS net_loss,
        CAST(0 AS decimal(7,2)) AS net_profit,
        CAST(0 AS decimal(15,2)) AS promo_cost,
        SUM(cr.cr_return_quantity) AS total_quantity
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN date_dim d_cr_fiscal ON cr.cr_returned_date_sk = d_cr_fiscal.d_date_sk
    GROUP BY d_cr.d_date, d_cr_fiscal.d_fy_year
),
combined AS (
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM catalog_agg
)
SELECT
    return_source,
    return_date,
    fiscal_year,
    net_loss,
    net_profit,
    promo_cost,
    total_quantity,
    SUM(net_loss) OVER (
        PARTITION BY return_source
        ORDER BY return_date
        ROWS UNBOUNDED PRECEDING
    ) AS cum_net_loss,
    LAG(net_profit) OVER (
        PARTITION BY return_source
        ORDER BY return_date
    ) AS prev_net_profit
FROM combined
ORDER BY return_source, return_date
LIMIT 100
