WITH
    avg_return AS (
        SELECT AVG(cr_return_amount) AS avg_ret_amt
        FROM catalog_returns
    ),
    warehouse_addr AS (
        SELECT
            w_warehouse_sk,
            w_warehouse_name,
            ARRAY[w_street_number, w_street_name, w_city, w_state] AS addr_parts
        FROM warehouse
    ),
    returns_with_profit AS (
        SELECT DISTINCT
            w.w_warehouse_sk,
            w.w_warehouse_name
        FROM catalog_returns cr
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
        WHERE cr.cr_return_amount > (SELECT avg_ret_amt FROM avg_return)
          AND EXISTS (
              SELECT 1
              FROM web_page wp
              WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
          )
    ),
    sales_warehouses AS (
        SELECT DISTINCT
            w.w_warehouse_sk,
            w.w_warehouse_name
        FROM warehouse w
        JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE ws.ws_net_profit > 0
    )
SELECT
    diff.w_warehouse_sk,
    diff.w_warehouse_name,
    addr_part AS address_component
FROM (
    SELECT w_warehouse_sk, w_warehouse_name
    FROM returns_with_profit
    EXCEPT
    SELECT w_warehouse_sk, w_warehouse_name
    FROM sales_warehouses
) AS diff
JOIN warehouse_addr wa ON wa.w_warehouse_sk = diff.w_warehouse_sk
CROSS JOIN UNNEST(wa.addr_parts) AS t (addr_part)
ORDER BY diff.w_warehouse_name
LIMIT 100
