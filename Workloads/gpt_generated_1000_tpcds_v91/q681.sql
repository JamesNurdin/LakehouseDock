WITH eligible_warehouses AS (
    SELECT w.w_warehouse_sk
    FROM warehouse w
    WHERE regexp_like(w.w_county, 'County')
    INTERSECT
    SELECT cs.cs_warehouse_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 2000
),
sales_summary AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_county,
        d.d_year,
        concat(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_label,
        substring(w.w_warehouse_name, 1, 10) AS short_name,
        regexp_extract(w.w_warehouse_id, '(A+)', 1) AS id_prefix,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        sum(cs.cs_ext_sales_price) AS total_ext_sales_price,
        CASE
            WHEN sum(cs.cs_net_profit) > (
                SELECT avg(cs2.cs_net_profit)
                FROM catalog_sales cs2
                JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
                WHERE d2.d_date >= DATE '2000-01-01'
                  AND d2.d_date < DATE '2000-04-01'
            ) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS profit_vs_avg
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM eligible_warehouses)
      AND d.d_date >= DATE '2000-01-01'
      AND d.d_date < DATE '2000-04-01'
      AND w.w_warehouse_name LIKE '%WARE%'
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        w.w_county,
        d.d_year
)
SELECT
    ss.w_warehouse_id,
    ss.warehouse_label,
    ss.short_name,
    ss.id_prefix,
    ss.d_year,
    ss.total_net_paid,
    ss.total_net_profit,
    ss.profit_vs_avg,
    CASE
        WHEN ss.total_net_profit > 50000 THEN 'High'
        WHEN ss.total_net_profit > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM sales_summary ss
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE dr.d_date >= DATE '2000-01-01'
      AND dr.d_date < DATE '2000-04-01'
      AND ca.ca_county = ss.w_county
)
ORDER BY ss.total_net_profit DESC
LIMIT 100
