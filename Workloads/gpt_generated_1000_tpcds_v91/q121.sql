WITH base AS (
    SELECT
        d_sales.d_date,
        d_sales.d_year,
        t.t_hour,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        cc.cc_name,
        ws.web_name,
        tl.min_minute,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(DISTINCT hd.hd_vehicle_count) AS distinct_vehicle_counts
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sales.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    CROSS JOIN LATERAL (
        SELECT MIN(t2.t_minute) AS min_minute
        FROM time_dim t2
        WHERE t2.t_time_sk = ss.ss_sold_time_sk
    ) tl
    WHERE NOT EXISTS (
        SELECT 1
        FROM (
            SELECT DISTINCT ws2.web_manager
            FROM web_site ws2
            WHERE ws2.web_zip = '33511'
        ) excl
        WHERE excl.web_manager = ws.web_manager
    )
    GROUP BY
        d_sales.d_date,
        d_sales.d_year,
        t.t_hour,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        cc.cc_name,
        ws.web_name,
        tl.min_minute
    HAVING COUNT(DISTINCT ss.ss_customer_sk) > 5
)
SELECT
    base.d_date,
    base.d_year,
    base.t_hour,
    base.ca_state,
    base.cd_gender,
    base.hd_buy_potential,
    base.cc_name,
    base.web_name,
    base.min_minute,
    base.total_sales,
    base.total_net_paid,
    base.distinct_customers,
    base.distinct_vehicle_counts,
    ROW_NUMBER() OVER (PARTITION BY base.d_year ORDER BY base.total_sales DESC) AS sales_rank_year,
    SUM(base.total_sales) OVER (PARTITION BY base.ca_state ORDER BY base.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_by_state
FROM base
ORDER BY base.d_date DESC, sales_rank_year
LIMIT 100
