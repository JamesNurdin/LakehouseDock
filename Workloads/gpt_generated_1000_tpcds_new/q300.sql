WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        d.d_year,
        d.d_date,
        t.t_hour,
        cc.cc_name,
        cc.cc_country,
        ib.ib_upper_bound,
        cd.cd_gender,
        hd.hd_vehicle_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 8 AND 16
      AND cc.cc_country = 'United States'
      AND ib.ib_upper_bound <= 200000
      AND ss.ss_quantity > 0
),

sales_no_return AS (
    SELECT sb.ss_ticket_number
    FROM sales_base sb
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = sb.ss_ticket_number
    )
),

web_sales_qty_agg AS (
    SELECT
        ws.ws_order_number,
        array_agg(ws.ws_quantity) AS qty_array
    FROM web_sales ws
    GROUP BY ws.ws_order_number
),

web_sales_with_return AS (
    SELECT DISTINCT ws.ws_order_number
    FROM web_sales ws
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_ship_cost > 100
),

intersect_keys AS (
    SELECT ss_ticket_number AS ticket
    FROM sales_no_return
    INTERSECT
    SELECT ws_order_number AS ticket
    FROM web_sales_with_return
)

SELECT
    sb.ss_ticket_number,
    sb.d_year,
    sb.t_hour,
    sb.cc_name,
    sb.ib_upper_bound,
    SUM(sb.ss_quantity) AS total_store_quantity,
    SUM(ws_qty) AS total_web_quantity,
    COUNT(*) AS rows_count
FROM intersect_keys ik
JOIN sales_base sb ON sb.ss_ticket_number = ik.ticket
JOIN web_sales_qty_agg wq ON wq.ws_order_number = ik.ticket
CROSS JOIN UNNEST(wq.qty_array) AS t(ws_qty)
GROUP BY
    sb.ss_ticket_number,
    sb.d_year,
    sb.t_hour,
    sb.cc_name,
    sb.ib_upper_bound
ORDER BY total_store_quantity DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
