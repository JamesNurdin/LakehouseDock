WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY ss_item_sk, ss_store_sk, ss_promo_sk, ss_sold_date_sk, ss_sold_time_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_web_site_sk,
        ws_web_page_sk,
        ws_sold_date_sk,
        ws_sold_time_sk,
        SUM(ws_net_paid) AS total_ws_net_paid,
        SUM(ws_net_profit) AS total_ws_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY ws_item_sk, ws_web_site_sk, ws_web_page_sk, ws_sold_date_sk, ws_sold_time_sk
)
SELECT
    s.s_store_name,
    d_sold.d_year,
    i.i_product_name,
    p.p_promo_name,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit,
    inv.inv_quantity_on_hand,
    ws_agg.total_ws_net_paid,
    ws_agg.total_ws_net_profit,
    cp.cp_catalog_page_number,
    ws_site.web_name,
    wp.wp_url,
    ca.ca_city,
    t_sold.t_hour AS store_sale_hour,
    t_ws.t_hour AS web_sale_hour
FROM ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold ON ss_agg.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON ss_agg.ss_sold_time_sk = t_sold.t_time_sk
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss_agg.ss_promo_sk = p.p_promo_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
JOIN ws_agg ON ws_agg.ws_item_sk = i.i_item_sk AND ws_agg.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site ws_site ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN time_dim t_ws ON ws_agg.ws_sold_time_sk = t_ws.t_time_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE d_sold.d_year = 2001
GROUP BY
    s.s_store_name,
    d_sold.d_year,
    i.i_product_name,
    p.p_promo_name,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit,
    inv.inv_quantity_on_hand,
    ws_agg.total_ws_net_paid,
    ws_agg.total_ws_net_profit,
    cp.cp_catalog_page_number,
    ws_site.web_name,
    wp.wp_url,
    ca.ca_city,
    t_sold.t_hour,
    t_ws.t_hour
LIMIT 100
