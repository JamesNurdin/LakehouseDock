WITH filtered_dates AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 1999
)
SELECT
    s.s_store_name,
    cc.cc_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_cs_net_paid,
    SUM(ws.ws_net_paid) AS total_ws_net_paid,
    ROUND(
        (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)) /
        NULLIF(COUNT(DISTINCT cs.cs_order_number) + COUNT(DISTINCT ws.ws_order_number), 0),
        2
    ) AS avg_net_paid_per_order,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN filtered_dates d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sold.d_year
          AND d2.d_month_seq = d_sold.d_month_seq
    ) AS month_avg_cs_net_profit,
    (
        SELECT SUM(ws2.ws_net_profit)
        FROM web_sales ws2
        JOIN filtered_dates d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_sold.d_year
          AND d2.d_month_seq = d_sold.d_month_seq
    ) AS month_ws_total_profit,
    CASE 
        WHEN ib.ib_upper_bound <= 30000 THEN 'Low'
        WHEN ib.ib_upper_bound <= 70000 THEN 'Medium'
        ELSE 'High'
    END AS income_bracket
FROM
    catalog_sales cs
    JOIN filtered_dates d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
        AND ws.ws_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN time_dim t_ws
        ON ws.ws_sold_time_sk = t_ws.t_time_sk
WHERE
    sm.sm_type IS NOT NULL
GROUP BY
    s.s_store_name,
    cc.cc_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    cd.cd_gender,
    sm.sm_type,
    ib.ib_upper_bound
ORDER BY
    total_cs_net_paid DESC,
    total_ws_net_paid DESC
LIMIT 100
