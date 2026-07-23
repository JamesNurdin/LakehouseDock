WITH union_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_ship_date_sk AS ship_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_catalog_page_sk AS catalog_page_sk,
        cs.cs_bill_addr_sk AS bill_addr_sk,
        cs.cs_ship_addr_sk AS ship_addr_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        NULL AS web_site_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_sold_time_sk AS sold_time_sk,
        ws.ws_ship_date_sk AS ship_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_order_number AS order_number,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        NULL AS call_center_sk,
        NULL AS catalog_page_sk,
        ws.ws_bill_addr_sk AS bill_addr_sk,
        ws.ws_ship_addr_sk AS ship_addr_sk,
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_web_site_sk AS web_site_sk
    FROM web_sales ws
),
avg_profit AS (
    SELECT AVG(net_profit) AS avg_net_profit FROM union_sales
)
SELECT
    d.d_date AS sale_date,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    p.p_promo_name,
    sm.sm_type AS ship_mode_type,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    union_sales.quantity,
    union_sales.net_paid,
    union_sales.net_profit,
    RANK() OVER (PARTITION BY i.i_category ORDER BY union_sales.net_profit DESC) AS profit_rank,
    SUM(union_sales.net_paid) OVER (PARTITION BY i.i_category ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid,
    CASE
        WHEN union_sales.net_profit > (SELECT avg_net_profit FROM avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg,
    COALESCE(r_cr.r_reason_desc, r_wr.r_reason_desc) AS return_reason,
    cc.cc_name AS call_center_name,
    cp.cp_description AS catalog_page_desc,
    ws_site.web_name AS web_site_name
FROM union_sales
JOIN date_dim d ON union_sales.sold_date_sk = d.d_date_sk
JOIN time_dim t ON union_sales.sold_time_sk = t.t_time_sk
JOIN item i ON union_sales.item_sk = i.i_item_sk
JOIN promotion p ON union_sales.promo_sk = p.p_promo_sk
JOIN ship_mode sm ON union_sales.ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_bill ON union_sales.bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON union_sales.ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN call_center cc ON union_sales.call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON union_sales.catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_site ws_site ON union_sales.web_site_sk = ws_site.web_site_sk
LEFT JOIN catalog_returns cr ON union_sales.order_number = cr.cr_order_number
LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN web_returns wr ON union_sales.order_number = wr.wr_order_number
LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
    d.d_year = 2000
    AND i.i_category = 'Electronics'
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 9 AND 17
    AND ca_bill.ca_country = 'United States'
    AND cp.cp_catalog_number IN (1, 3, 4)
ORDER BY profit_rank, sale_date DESC
LIMIT 100
