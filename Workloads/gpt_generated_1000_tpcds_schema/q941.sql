WITH
    cr_joined AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_item_sk,
            cr.cr_return_amount,
            cr.cr_net_loss,
            t.t_hour,
            t.t_am_pm,
            i.i_item_desc,
            i.i_product_name,
            w.w_city,
            w.w_gmt_offset
        FROM catalog_returns cr
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE regexp_like(i.i_item_desc, '(?i)steel|plastic')
    ),
    ws_joined AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_item_sk,
            ws.ws_net_paid,
            ws.ws_net_profit,
            t.t_hour,
            t.t_am_pm,
            i.i_item_desc,
            i.i_product_name,
            w.w_city,
            w.w_gmt_offset
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE i.i_product_name LIKE '%Pro%'
    ),
    combined_full AS (
        SELECT
            COALESCE(cr.cr_returned_date_sk, ws.ws_sold_date_sk) AS date_sk,
            COALESCE(cr.t_hour, ws.t_hour) AS hour,
            COALESCE(cr.i_item_desc, ws.i_item_desc) AS item_desc,
            COALESCE(cr.w_city, ws.w_city) AS city,
            CASE
                WHEN cr.cr_net_loss IS NOT NULL THEN cr.cr_net_loss
                ELSE -ws.ws_net_paid
            END AS loss_or_negative_paid,
            CASE
                WHEN cr.cr_return_amount > 100 THEN 'HIGH_RETURN'
                ELSE 'LOW_RETURN'
            END AS return_category
        FROM cr_joined cr
        FULL OUTER JOIN ws_joined ws
            ON cr.cr_returned_time_sk = ws.ws_sold_time_sk
    ),
    union_sets AS (
        SELECT
            city,
            hour,
            SUM(loss_or_negative_paid) AS total_amount,
            COUNT(*) AS cnt,
            return_category
        FROM combined_full
        GROUP BY city, hour, return_category

        UNION DISTINCT

        SELECT
            w.w_city AS city,
            t.t_hour AS hour,
            SUM(ws.ws_net_profit) AS total_amount,
            COUNT(*) AS cnt,
            CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS return_category
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE regexp_extract(w.w_city, '(.*)') IS NOT NULL
        GROUP BY w.w_city, t.t_hour
    )
SELECT
    city,
    hour,
    total_amount,
    cnt,
    return_category,
    CONCAT(city, ':', CAST(hour AS VARCHAR)) AS city_hour_key,
    SUBSTRING(city FROM 1 FOR 3) AS city_prefix
FROM union_sets
ORDER BY total_amount DESC, city
LIMIT 100
