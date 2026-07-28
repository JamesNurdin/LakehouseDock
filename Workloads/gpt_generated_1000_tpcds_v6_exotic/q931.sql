WITH sales_warehouse AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        w.w_warehouse_name,
        w.w_state,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(ca.ca_city, '^A.*')      -- cities beginning with "A"
      AND ca.ca_zip LIKE '9%'                -- ZIP codes starting with 9
)
SELECT
    w_warehouse_name,
    w_state,
    regexp_extract(ca_zip, '(\\d{3})', 1) AS zip_prefix,
    SUM(ss_net_profit) AS total_profit,
    AVG(inv_quantity_on_hand) AS avg_qty_on_hand,
    CONCAT(ca_city, ', ', ca_state) AS city_state
FROM sales_warehouse
GROUP BY
    w_warehouse_name,
    w_state,
    regexp_extract(ca_zip, '(\\d{3})', 1),
    CONCAT(ca_city, ', ', ca_state)
ORDER BY total_profit DESC
LIMIT 100
