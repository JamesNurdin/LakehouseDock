WITH sales_agg AS (
    SELECT
        p.p_promo_name,
        sd.d_year,
        sd.d_month_seq,
        sm.sm_type,
        ws_site.web_name,
        sum(ws.ws_net_profit) AS total_net_profit,
        sum(ws.ws_ext_sales_price) AS total_sales_amount,
        sum(ws.ws_quantity) AS total_quantity,
        avg(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE sd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY p.p_promo_name, sd.d_year, sd.d_month_seq, sm.sm_type, ws_site.web_name
),
returns_agg AS (
    SELECT
        p.p_promo_name,
        sd.d_year,
        sd.d_month_seq,
        sm.sm_type,
        ws_site.web_name,
        sum(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE sd.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY p.p_promo_name, sd.d_year, sd.d_month_seq, sm.sm_type, ws_site.web_name
)
SELECT
    s.p_promo_name,
    s.d_year,
    s.d_month_seq,
    s.sm_type,
    s.web_name,
    s.total_sales_amount,
    s.total_net_profit,
    s.total_quantity,
    s.avg_discount,
    coalesce(r.total_return_amount, 0) AS total_return_amount,
    s.total_net_profit - coalesce(r.total_return_amount, 0) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.p_promo_name = r.p_promo_name
    AND s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.sm_type = r.sm_type
    AND s.web_name = r.web_name
ORDER BY s.d_year, s.d_month_seq, net_profit_after_returns DESC
