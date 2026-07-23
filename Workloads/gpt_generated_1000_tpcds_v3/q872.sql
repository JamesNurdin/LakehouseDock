WITH per_warehouse_shipmode AS (
    SELECT
        w.w_warehouse_id,
        w.w_county,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(ws.ws_quantity) AS web_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month IN (4, 7, 12)
      AND w.w_county = 'Williamson County'
      AND sm.sm_type = 'AIR'
    GROUP BY w.w_warehouse_id, w.w_county, sm.sm_type
), agg AS (
    SELECT
        w_warehouse_id,
        w_county,
        sm_type,
        catalog_net_profit,
        web_net_profit,
        (catalog_net_profit + web_net_profit) AS total_net_profit,
        (catalog_discount + web_discount) AS total_discount,
        distinct_customers,
        (catalog_quantity + web_quantity) AS total_quantity,
        (catalog_net_profit + web_net_profit) / NULLIF(distinct_customers, 0) AS avg_profit_per_customer
    FROM per_warehouse_shipmode
)
SELECT
    w_warehouse_id,
    w_county,
    sm_type,
    catalog_net_profit,
    web_net_profit,
    total_net_profit,
    total_discount,
    distinct_customers,
    total_quantity,
    avg_profit_per_customer
FROM agg
WHERE total_net_profit > 10000
  AND distinct_customers >= 5
  AND total_quantity > 20
ORDER BY total_net_profit DESC
LIMIT 100
