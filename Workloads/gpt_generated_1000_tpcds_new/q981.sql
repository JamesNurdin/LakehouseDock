WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_warehouse_sk,
       cs.cs_ship_mode_sk,
       cs.cs_net_paid_inc_ship,
       cs.cs_net_profit,
       sm.sm_carrier,
       sm.sm_code,
       w.w_city,
       w.w_street_name,
       w.w_warehouse_sq_ft
   FROM catalog_sales cs
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE regexp_like(sm.sm_carrier, '^F.*')               -- carriers that start with "F" (e.g., FEDEX)
     AND w.w_street_name LIKE '%Sunset%'                -- street names containing "Sunset"
),
agg AS (
   SELECT
       b.cs_warehouse_sk,
       b.cs_ship_mode_sk,
       sum(b.cs_net_paid_inc_ship)   AS total_paid,
       sum(b.cs_net_profit)          AS total_profit,
       count(*)                      AS order_cnt,
       max(b.w_warehouse_sq_ft)      AS warehouse_sq_ft,
       max(b.w_city)                 AS city,
       max(b.sm_code)                AS ship_code,
       max(b.sm_carrier)             AS carrier
   FROM base b
   GROUP BY b.cs_warehouse_sk, b.cs_ship_mode_sk
)
SELECT
   a.cs_warehouse_sk,
   a.cs_ship_mode_sk,
   a.total_paid,
   a.total_profit,
   a.order_cnt,
   a.warehouse_sq_ft,
   a.city,
   a.ship_code,
   CASE WHEN a.total_profit > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_level,
   substr(a.city, 1, 3) || '-' || a.ship_code                AS city_ship_key,
   l.street_number
FROM agg a
JOIN ship_mode sm ON a.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w   ON a.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN LATERAL (
   SELECT regexp_extract(w.w_street_name, '(\\d+)') AS street_number
) l ON true
WHERE regexp_like(sm.sm_code, '^(AIR|SURFACE)$')
ORDER BY a.total_paid DESC
OFFSET 10
LIMIT 100
