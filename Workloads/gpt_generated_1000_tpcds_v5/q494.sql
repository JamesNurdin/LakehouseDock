WITH combined AS (
    SELECT
        'catalog' AS source,
        w.w_warehouse_name AS warehouse_name,
        ca.ca_state AS state,
        t.t_hour AS hour,
        cr.cr_return_amount AS total_amount,
        cr.cr_net_loss AS total_loss
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND ca.ca_gmt_offset = -5.00
      AND hd.hd_vehicle_count > 1
      AND w.w_state = 'CA'

    UNION ALL

    SELECT
        'store' AS source,
        NULL AS warehouse_name,
        ca.ca_state AS state,
        t.t_hour AS hour,
        sr.sr_return_amt AS total_amount,
        sr.sr_net_loss AS total_loss
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND ca.ca_gmt_offset = -5.00
      AND hd.hd_vehicle_count > 1
      AND sr.sr_return_ship_cost > 100

    UNION ALL

    SELECT
        'web' AS source,
        w.w_warehouse_name AS warehouse_name,
        ca.ca_state AS state,
        t.t_hour AS hour,
        ws.ws_ext_sales_price AS total_amount,
        0.0 AS total_loss
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND ca.ca_gmt_offset = -5.00
      AND hd.hd_vehicle_count > 1
      AND web.web_country = 'United States'
      AND w.w_state = 'CA'
),
agg AS (
    SELECT
        source,
        warehouse_name,
        state,
        hour,
        SUM(total_amount) AS total_amount,
        SUM(total_loss) AS total_loss,
        CASE WHEN SUM(total_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM combined
    GROUP BY GROUPING SETS (
        (source, warehouse_name, state, hour),
        (source, warehouse_name, state),
        (source, warehouse_name),
        (source)
    )
)
SELECT
    source,
    warehouse_name,
    state,
    hour,
    total_amount,
    total_loss,
    amount_category,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_amount DESC) AS rank_within_source
FROM agg
ORDER BY source, rank_within_source
LIMIT 100
