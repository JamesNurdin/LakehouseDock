SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    p.p_promo_name AS promo_name,
    cp.cp_catalog_page_number AS catalog_page_no,
    s.s_state AS store_state,
    CASE WHEN ws.ws_ext_discount_amt > 5 THEN 'High' ELSE 'Low' END AS discount_tier,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_qty_sales,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    MIN(d_p_start.d_year) AS promo_start_year,
    MIN(d_p_end.d_year) AS promo_end_year,
    MIN(d_cp_end.d_year) AS catalog_page_end_year,
    MIN(d_ship.d_month_seq) AS ship_month
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_p_start
    ON p.p_start_date_sk = d_p_start.d_date_sk
JOIN date_dim d_p_end
    ON p.p_end_date_sk = d_p_end.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE ws.ws_sold_date_sk >= p.p_start_date_sk
  AND ws.ws_sold_date_sk <= p.p_end_date_sk
  AND ws.ws_sold_date_sk >= cp.cp_start_date_sk
  AND ws.ws_sold_date_sk <= cp.cp_end_date_sk
  AND d_sold.d_year >= 2015
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    cp.cp_catalog_page_number,
    s.s_state,
    CASE WHEN ws.ws_ext_discount_amt > 5 THEN 'High' ELSE 'Low' END
HAVING SUM(ws.ws_ext_sales_price) > 10000
