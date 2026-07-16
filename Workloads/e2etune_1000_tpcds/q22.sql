SELECT
    wsite.web_name AS web_site,
    p.p_promo_name AS promotion_name,
    hd.hd_income_band_sk AS income_band,
    d_sold.d_year AS sales_year,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
WHERE
    p.p_discount_active = 'Y'
    AND cp.cp_department = 'DEPARTMENT'
    AND d_sold.d_year = 2001
    AND d_sold.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    AND d_sold.d_date_sk >= wsite.web_open_date_sk
    AND d_sold.d_date_sk <= wsite.web_close_date_sk
GROUP BY
    wsite.web_name,
    p.p_promo_name,
    hd.hd_income_band_sk,
    d_sold.d_year
HAVING
    SUM(ws.ws_net_profit) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 10
