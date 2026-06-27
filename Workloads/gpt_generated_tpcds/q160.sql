WITH sales AS (
    SELECT
        d.d_year,
        d.d_moy AS month_of_year,
        i.i_category,
        p.p_promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category, p.p_promo_name
),
returns AS (
    SELECT
        d.d_year,
        d.d_moy AS month_of_year,
        i.i_category,
        p.p_promo_name,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT wr.wr_order_number) AS return_order_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category, p.p_promo_name
)
SELECT
    s.d_year,
    s.month_of_year,
    s.i_category,
    s.p_promo_name,
    s.total_net_paid,
    s.total_net_profit,
    s.total_quantity,
    s.order_cnt,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.return_order_cnt, 0) AS return_order_cnt,
    CASE WHEN s.total_net_paid > 0
         THEN COALESCE(r.total_return_amt, 0) / s.total_net_paid
         ELSE NULL END AS return_rate_amount,
    CASE WHEN s.order_cnt > 0
         THEN COALESCE(r.return_order_cnt, 0) * 1.0 / s.order_cnt
         ELSE NULL END AS return_rate_orders
FROM sales s
LEFT JOIN returns r
    ON s.d_year = r.d_year
   AND s.month_of_year = r.month_of_year
   AND s.i_category = r.i_category
   AND COALESCE(s.p_promo_name, '') = COALESCE(r.p_promo_name, '')
ORDER BY s.d_year, s.month_of_year, s.i_category, s.p_promo_name
