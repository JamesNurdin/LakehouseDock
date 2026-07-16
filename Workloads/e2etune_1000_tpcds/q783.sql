WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        d_start.d_year AS start_year,
        d_start.d_month_seq AS start_month_seq,
        d_end.d_year AS end_year,
        d_end.d_month_seq AS end_month_seq,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d_start.d_year = 2002
    GROUP BY p.p_promo_sk, p.p_promo_name, d_start.d_year, d_start.d_month_seq,
             d_end.d_year, d_end.d_month_seq, i.i_category
),
promo_returns AS (
    SELECT
        p.p_promo_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE p.p_discount_active = 'Y'
      AND d_ret.d_year = 2002
    GROUP BY p.p_promo_sk
)
SELECT
    ps.p_promo_name,
    ps.i_category,
    ps.start_year,
    ps.start_month_seq,
    ps.total_sales,
    ps.total_discount,
    ps.total_net_profit,
    COALESCE(pr.total_return_amount, 0) AS total_return_amount,
    COALESCE(pr.total_return_qty, 0) AS total_return_qty,
    CASE WHEN ps.total_sales > 0 THEN COALESCE(pr.total_return_amount, 0) / ps.total_sales ELSE NULL END AS return_rate
FROM promo_sales ps
LEFT JOIN promo_returns pr ON ps.p_promo_sk = pr.p_promo_sk
ORDER BY return_rate DESC
LIMIT 100
