WITH cat_agg AS (
    SELECT
        'catalog' AS source_type,
        cc.cc_call_center_id AS location_id,
        cc.cc_name AS location_name,
        td.t_shift AS period,
        regexp_extract(cc.cc_name, '([A-Za-z]+)', 1) AS name_prefix,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        concat('catalog:', cc.cc_call_center_id) AS label
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE regexp_like(cc.cc_name, '^.*Center.*$')
      AND td.t_shift = 'first'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        td.t_shift,
        regexp_extract(cc.cc_name, '([A-Za-z]+)', 1),
        concat('catalog:', cc.cc_call_center_id)
),
web_agg AS (
    SELECT
        'web' AS source_type,
        w.w_warehouse_id AS location_id,
        w.w_warehouse_name AS location_name,
        td.t_meal_time AS period,
        regexp_extract(w.w_warehouse_name, '([A-Za-z]+)', 1) AS name_prefix,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        concat('web:', w.w_warehouse_id) AS label
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE w.w_warehouse_name LIKE '%Warehouse%'
      AND td.t_meal_time = 'lunch'
    GROUP BY
        w.w_warehouse_id,
        w.w_warehouse_name,
        td.t_meal_time,
        regexp_extract(w.w_warehouse_name, '([A-Za-z]+)', 1),
        concat('web:', w.w_warehouse_id)
)
SELECT
    source_type,
    location_id,
    location_name,
    period,
    name_prefix,
    total_profit,
    total_sales,
    label
FROM cat_agg
UNION ALL
SELECT
    source_type,
    location_id,
    location_name,
    period,
    name_prefix,
    total_profit,
    total_sales,
    label
FROM web_agg
ORDER BY total_profit DESC
LIMIT 100
