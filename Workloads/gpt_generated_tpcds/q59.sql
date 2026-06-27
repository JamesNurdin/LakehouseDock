WITH sales_enriched AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date,
        t.t_hour,
        p.p_promo_name,
        p.p_discount_active,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        s.web_site_id,
        s.web_name
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE d_sold.d_date >= DATE '2001-01-01' AND d_sold.d_date <= DATE '2001-12-31'
)
SELECT
    s.web_site_id,
    s.web_name,
    s.d_year,
    s.d_month_seq,
    s.t_hour,
    SUM(s.ws_net_profit) AS total_net_profit,
    SUM(s.ws_ext_sales_price) AS total_sales,
    SUM(s.ws_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT s.ws_order_number) AS order_count,
    COUNT(DISTINCT s.p_promo_name) AS distinct_promotions_used,
    AVG(s.ws_quantity) AS avg_quantity_per_order
FROM sales_enriched s
GROUP BY s.web_site_id, s.web_name, s.d_year, s.d_month_seq, s.t_hour
ORDER BY total_net_profit DESC
LIMIT 100
