-- Monthly promotion performance (net profit vs. returns) for 2001
WITH promo_monthly AS (
    SELECT
        ds.d_year,
        ds.d_moy,
        promotion.p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount_inc_tax,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN promotion ON ws.ws_promo_sk = promotion.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    WHERE ds.d_date >= DATE '2001-01-01' AND ds.d_date <= DATE '2001-12-31'
      AND (dr.d_date IS NULL OR (dr.d_date >= DATE '2001-01-01' AND dr.d_date <= DATE '2001-12-31'))
    GROUP BY ds.d_year, ds.d_moy, promotion.p_promo_name
)
SELECT
    d_year,
    d_moy,
    p_promo_name,
    total_net_profit,
    total_return_amount_inc_tax,
    distinct_orders,
    distinct_items_sold,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_moy ORDER BY total_net_profit DESC) AS promo_rank
FROM promo_monthly
ORDER BY d_year, d_moy, promo_rank
LIMIT 20
