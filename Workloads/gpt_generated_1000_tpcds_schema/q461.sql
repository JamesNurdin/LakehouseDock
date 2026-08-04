WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_bill_addr_sk,
        cs_ship_addr_sk,
        cs_warehouse_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*) AS cnt_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY cs_item_sk, cs_order_number, cs_bill_addr_sk, cs_ship_addr_sk, cs_warehouse_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_bill_addr_sk,
        ws_ship_addr_sk,
        ws_warehouse_sk,
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(*) AS cnt_web
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY ws_item_sk, ws_order_number, ws_bill_addr_sk, ws_ship_addr_sk, ws_warehouse_sk, ws_web_page_sk
),
order_without_return AS (
    SELECT cs_order_number
    FROM cs_agg
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
)
SELECT
    cs_agg.cs_item_sk,
    cs_agg.cs_order_number,
    cs_agg.total_sales,
    ws_agg.total_web_sales,
    COUNT(DISTINCT s.s_store_id) AS distinct_store_cnt,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_net_loss,
    MIN(w.w_warehouse_name) AS warehouse_name,
    r.r_reason_desc,
    CASE
        WHEN ws_agg.total_web_sales > cs_agg.total_sales THEN 'WEB > CAT'
        ELSE 'CAT >= WEB'
    END AS sales_cmp
FROM cs_agg
JOIN catalog_returns cr
    ON cs_agg.cs_item_sk = cr.cr_item_sk
   AND cs_agg.cs_order_number = cr.cr_order_number
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN ws_agg
    ON cs_agg.cs_item_sk = ws_agg.ws_item_sk
   AND cs_agg.cs_order_number = ws_agg.ws_order_number
JOIN web_page wp
    ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca_bill
    ON cs_agg.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs_agg.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_address ca_ws_bill
    ON ws_agg.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship
    ON ws_agg.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
LEFT JOIN store_returns sr
    ON sr.sr_addr_sk = ca_bill.ca_address_sk
LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r2
    ON sr.sr_reason_sk = r2.r_reason_sk
WHERE
    ca_bill.ca_country = 'United States'
    AND r.r_reason_desc LIKE 'Did not like the warranty%'
    AND w.w_city = 'New York'
    AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_item_sk = cs_agg.cs_item_sk
          AND sr2.sr_store_sk = s.s_store_sk
    )
    AND cs_agg.cs_order_number IN (SELECT cs_order_number FROM order_without_return)
GROUP BY
    cs_agg.cs_item_sk,
    cs_agg.cs_order_number,
    cs_agg.total_sales,
    ws_agg.total_web_sales,
    w.w_warehouse_name,
    r.r_reason_desc,
    CASE
        WHEN ws_agg.total_web_sales > cs_agg.total_sales THEN 'WEB > CAT'
        ELSE 'CAT >= WEB'
    END
ORDER BY total_net_loss DESC
LIMIT 100
