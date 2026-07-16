WITH unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_store_sk AS store_sk,
        CAST(NULL AS INTEGER) AS warehouse_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS order_number
    FROM store_sales ss

    UNION ALL

    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_promo_sk AS promo_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit,
        cs.cs_order_number AS order_number
    FROM catalog_sales cs

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_promo_sk AS promo_sk,
        CAST(NULL AS INTEGER) AS store_sk,
        ws.ws_warehouse_sk AS warehouse_sk,
        CAST(NULL AS INTEGER) AS call_center_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS order_number
    FROM web_sales ws
), returns AS (
    SELECT sr.sr_ticket_number AS order_number, sr.sr_reason_sk AS reason_sk
    FROM store_returns sr
    UNION ALL
    SELECT cr.cr_order_number AS order_number, cr.cr_reason_sk AS reason_sk
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_order_number AS order_number, wr.wr_reason_sk AS reason_sk
    FROM web_returns wr
)
SELECT
    d.d_year,
    i.i_category,
    i.i_class,
    COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
    COALESCE(cc.cc_name, 'NoCallCenter') AS call_center_name,
    COUNT(DISTINCT s.order_number) AS order_cnt,
    SUM(s.ext_sales_price) AS total_sales,
    SUM(s.net_profit) AS total_profit,
    AVG(s.quantity) AS avg_quantity,
    COUNT(r.reason_sk) AS return_cnt
FROM unified_sales s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
LEFT JOIN call_center cc ON s.call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns r ON s.order_number = r.order_number
GROUP BY
    d.d_year,
    i.i_category,
    i.i_class,
    COALESCE(p.p_promo_name, 'NoPromo'),
    COALESCE(cc.cc_name, 'NoCallCenter')
ORDER BY total_sales DESC
LIMIT 100
