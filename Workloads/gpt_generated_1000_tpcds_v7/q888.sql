WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        regexp_extract(i.i_product_name, '([0-9]{2})', 1) AS product_digits
    FROM tpcds.item i
    WHERE regexp_like(i.i_product_name, '[A-Z]{2}[0-9]{2}')
)
SELECT
    w.w_warehouse_name,
    f.i_brand,
    MIN(f.product_digits) AS example_digits,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    CONCAT(w.w_warehouse_name, ' - ', f.i_brand) AS warehouse_brand
FROM tpcds.web_sales ws
JOIN filtered_items f ON ws.ws_item_sk = f.i_item_sk
JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_warehouse_name LIKE '%WARE%'
GROUP BY w.w_warehouse_name, f.i_brand, CONCAT(w.w_warehouse_name, ' - ', f.i_brand)
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
