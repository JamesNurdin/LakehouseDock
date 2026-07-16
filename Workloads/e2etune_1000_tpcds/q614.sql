WITH sales AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_promo_sk,
        ws_quantity,
        ws_net_paid,
        ws_ext_discount_amt,
        ws_net_profit
    FROM web_sales
    WHERE ws_quantity > 5
      AND ws_ship_mode_sk IN (1, 2, 3, 4)
      AND ws_sold_date_sk BETWEEN 2450000 AND 2453650
),
returns AS (
    SELECT
        wr_order_number,
        wr_item_sk,
        wr_return_quantity,
        wr_return_amt_inc_tax,
        wr_net_loss
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_returned_date_sk BETWEEN 2450000 AND 2453650
),
sales_returns AS (
    SELECT
        s.ws_order_number,
        s.ws_item_sk,
        s.ws_sold_date_sk,
        s.ws_ship_mode_sk,
        s.ws_promo_sk,
        s.ws_quantity,
        s.ws_net_paid,
        s.ws_ext_discount_amt,
        s.ws_net_profit,
        COALESCE(r.wr_return_quantity, 0) AS return_quantity,
        COALESCE(r.wr_return_amt_inc_tax, 0) AS return_amt_inc_tax,
        COALESCE(r.wr_net_loss, 0) AS net_loss
    FROM sales s
    LEFT JOIN returns r
        ON s.ws_order_number = r.wr_order_number
       AND s.ws_item_sk = r.wr_item_sk
)
SELECT
    agg.ws_sold_date_sk,
    agg.ws_ship_mode_sk,
    agg.ws_promo_sk,
    agg.total_quantity,
    agg.net_paid_adj,
    agg.net_profit_adj,
    agg.avg_discount,
    ROW_NUMBER() OVER (PARTITION BY agg.ws_ship_mode_sk ORDER BY agg.net_profit_adj DESC) AS promo_rank_by_ship_mode
FROM (
    SELECT
        sr.ws_sold_date_sk,
        sr.ws_ship_mode_sk,
        sr.ws_promo_sk,
        SUM(sr.ws_quantity) AS total_quantity,
        SUM(sr.ws_net_paid) - SUM(sr.return_amt_inc_tax) AS net_paid_adj,
        SUM(sr.ws_net_profit) - SUM(sr.net_loss) AS net_profit_adj,
        AVG(sr.ws_ext_discount_amt) AS avg_discount
    FROM sales_returns sr
    GROUP BY sr.ws_sold_date_sk, sr.ws_ship_mode_sk, sr.ws_promo_sk
    HAVING SUM(sr.ws_quantity) > 10
) agg
ORDER BY agg.net_profit_adj DESC
LIMIT 100
