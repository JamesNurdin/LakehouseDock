SELECT
    ds_sales.d_year,
    ds_sales.d_month_seq,
    store.s_state,
    store.s_city,
    promotion.p_promo_name,
    COUNT(DISTINCT store_sales.ss_ticket_number) AS store_sales_transactions,
    SUM(store_sales.ss_ext_sales_price) AS store_sales_total,
    SUM(store_sales.ss_ext_discount_amt) AS store_sales_discount,
    COUNT(DISTINCT web_sales.ws_order_number) AS web_sales_orders,
    SUM(web_sales.ws_ext_sales_price) AS web_sales_total,
    SUM(web_sales.ws_ext_discount_amt) AS web_sales_discount,
    AVG(promotion.p_cost) AS avg_promo_cost,
    MAX(promotion.p_response_target) AS max_promo_response,
    MIN(ds_promo_start.d_date) AS promo_start_date,
    MAX(ds_promo_end.d_date) AS promo_end_date,
    SUM(CASE WHEN ds_ws_ship.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_shipments,
    SUM(CASE WHEN ds_store_closed.d_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS closed_store_days,
    (SUM(store_sales.ss_net_profit) + SUM(web_sales.ws_net_profit)) /
        NULLIF((SUM(store_sales.ss_ext_sales_price) + SUM(web_sales.ws_ext_sales_price)), 0) AS profit_margin,
    (SUM(store_sales.ss_ext_discount_amt) + SUM(web_sales.ws_ext_discount_amt)) /
        NULLIF((SUM(store_sales.ss_ext_sales_price) + SUM(web_sales.ws_ext_sales_price)), 0) AS discount_rate
FROM store_sales
JOIN date_dim AS ds_sales
    ON store_sales.ss_sold_date_sk = ds_sales.d_date_sk
JOIN store
    ON store_sales.ss_store_sk = store.s_store_sk
JOIN promotion
    ON store_sales.ss_promo_sk = promotion.p_promo_sk
JOIN date_dim AS ds_store_closed
    ON store.s_closed_date_sk = ds_store_closed.d_date_sk
JOIN date_dim AS ds_promo_start
    ON promotion.p_start_date_sk = ds_promo_start.d_date_sk
JOIN date_dim AS ds_promo_end
    ON promotion.p_end_date_sk = ds_promo_end.d_date_sk
JOIN web_sales
    ON web_sales.ws_promo_sk = promotion.p_promo_sk
    AND web_sales.ws_sold_date_sk = ds_sales.d_date_sk
JOIN date_dim AS ds_ws_ship
    ON web_sales.ws_ship_date_sk = ds_ws_ship.d_date_sk
GROUP BY GROUPING SETS (
    (ds_sales.d_year, ds_sales.d_month_seq, store.s_state, store.s_city, promotion.p_promo_name),
    (ds_sales.d_year, ds_sales.d_month_seq, store.s_state, store.s_city),
    (ds_sales.d_year, ds_sales.d_month_seq, store.s_state),
    (ds_sales.d_year, ds_sales.d_month_seq),
    (ds_sales.d_year),
    ()
)
HAVING (SUM(store_sales.ss_ext_sales_price) + SUM(web_sales.ws_ext_sales_price)) > 10000
ORDER BY ds_sales.d_year DESC, store.s_state, promotion.p_promo_name
LIMIT 100
