WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_item_sk,
        ws.ws_ext_ship_cost,
        i.i_item_sk,
        i.i_brand,
        i.i_formulation,
        i.i_rec_start_date,
        i.i_rec_end_date,
        cc.cc_name,
        cc.cc_state,
        cp.cp_department,
        cp.cp_type
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date <= DATE '2000-12-31'
      AND i.i_formulation LIKE '%steel%'
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'PROMO'
      AND ws.ws_ext_ship_cost > 1000.00
      AND ss.ss_wholesale_cost < 60.00
)
SELECT
    b.i_brand AS brand,
    b.cc_name AS call_center_name,
    b.cp_department AS department,
    COUNT(DISTINCT b.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT b.ss_ticket_number) AS store_tickets,
    COUNT(DISTINCT b.ws_order_number) AS web_orders,
    SUM(b.cs_net_profit) AS catalog_net_profit,
    SUM(b.ss_net_profit) AS store_net_profit,
    SUM(b.ws_net_profit) AS web_net_profit,
    SUM(b.cs_ext_sales_price) + SUM(b.ss_ext_sales_price) + SUM(b.ws_ext_sales_price) AS total_sales,
    (
        SELECT MAX(ws2.ws_net_paid)
        FROM web_sales ws2
        JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
        WHERE i2.i_brand = b.i_brand
    ) AS max_brand_web_net_paid,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
    ) AS avg_catalog_profit
FROM base b
GROUP BY b.i_brand, b.cc_name, b.cp_department
HAVING (SUM(b.cs_net_profit) + SUM(b.ss_net_profit) + SUM(b.ws_net_profit)) >
       (SELECT AVG(cs3.cs_net_profit) FROM catalog_sales cs3) * 1.5
ORDER BY total_sales DESC
LIMIT 100
