WITH avg_discount AS (
    SELECT avg(cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales
),
sales_by_entity AS (
    SELECT
        cc.cc_call_center_id AS entity_id,
        'call_center' AS entity_type,
        td.t_hour AS hour,
        sum(cs.cs_ext_sales_price) AS total_amount,
        (SELECT avg_discount FROM avg_discount) AS avg_discount_all
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
    GROUP BY cc.cc_call_center_id, td.t_hour
),
sales_by_warehouse AS (
    SELECT
        w.w_warehouse_id AS entity_id,
        'warehouse' AS entity_type,
        td.t_hour AS hour,
        sum(cs.cs_ext_sales_price) AS total_amount,
        (SELECT avg_discount FROM avg_discount) AS avg_discount_all
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_press = 'N'
    GROUP BY w.w_warehouse_id, td.t_hour
)
SELECT entity_id,
       entity_type,
       hour,
       total_amount,
       avg_discount_all
FROM sales_by_entity
UNION ALL
SELECT entity_id,
       entity_type,
       hour,
       total_amount,
       avg_discount_all
FROM sales_by_warehouse
ORDER BY total_amount DESC
LIMIT 100
