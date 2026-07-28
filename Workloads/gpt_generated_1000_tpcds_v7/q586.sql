WITH catalog AS (
    SELECT
        w.w_warehouse_id,
        regexp_extract(w.w_warehouse_id, 'A{7}([A-Z])', 1) AS region_code,
        concat(w.w_city, ', ', w.w_state) AS location,
        substr(w.w_street_name, 1, 4) AS street_prefix,
        time_dim.t_time,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN time_dim ON cs.cs_sold_time_sk = time_dim.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        regexp_like(time_dim.t_time_id, '^AAAAAAA[AB]')
        AND time_dim.t_hour BETWEEN 9 AND 17
        AND regexp_like(w.w_street_name, 'Elm')
),
web AS (
    SELECT
        w.w_warehouse_id,
        regexp_extract(w.w_warehouse_id, 'A{7}([A-Z])', 1) AS region_code,
        concat(w.w_city, ', ', w.w_state) AS location,
        substr(w.w_street_name, 1, 4) AS street_prefix,
        time_dim.t_time,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN time_dim ON ws.ws_sold_time_sk = time_dim.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        regexp_like(time_dim.t_time_id, '^AAAAAAA[AB]')
        AND time_dim.t_hour BETWEEN 9 AND 17
        AND w.w_street_name LIKE '%Elm%'
)
SELECT
    warehouse_id,
    region_code,
    location,
    street_prefix,
    COUNT(*) AS sales_count,
    SUM(net_profit) AS total_net_profit,
    AVG(net_profit) AS avg_net_profit,
    MAX(t_time) AS latest_time
FROM (
    SELECT
        w_warehouse_id AS warehouse_id,
        region_code,
        location,
        street_prefix,
        net_profit,
        t_time
    FROM catalog
    UNION ALL
    SELECT
        w_warehouse_id AS warehouse_id,
        region_code,
        location,
        street_prefix,
        net_profit,
        t_time
    FROM web
) combined
GROUP BY
    warehouse_id,
    region_code,
    location,
    street_prefix
ORDER BY
    total_net_profit DESC
LIMIT 15
