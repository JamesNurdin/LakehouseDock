WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_sales_cnt,
        SUM(p.p_cost) AS total_promo_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_net_profit,
    s.total_sales,
    s.order_cnt,
    s.promo_sales_cnt,
    s.total_promo_cost,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    CASE WHEN s.total_sales > 0 THEN COALESCE(r.total_return_amt, 0) / s.total_sales ELSE 0 END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_month_seq, s.i_category
