WITH store_part AS (
    SELECT
        d.d_year,
        i.i_category,
        ss.ss_net_profit               AS profit,
        ss.ss_ext_sales_price          AS sales_amount,
        'store'                        AS channel,
        cc.cc_name                     AS call_center_name,
        s.s_store_name                 AS store_name,
        NULL                           AS ship_code,
        t.t_hour                       AS hour_of_day,
        cust.c_customer_id             AS cust_id
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i              ON ss.ss_item_sk = i.i_item_sk
    JOIN store s             ON ss.ss_store_sk = s.s_store_sk
    JOIN call_center cc     ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer cust       ON ss.ss_customer_sk = cust.c_customer_sk
),
web_part AS (
    SELECT
        d.d_year,
        i.i_category,
        ws.ws_net_profit               AS profit,
        ws.ws_ext_sales_price          AS sales_amount,
        'web'                          AS channel,
        cc.cc_name                     AS call_center_name,
        NULL                           AS store_name,
        sm.sm_code                     AS ship_code,
        t.t_hour                       AS hour_of_day,
        cust.c_customer_id             AS cust_id
    FROM web_sales ws
    JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i              ON ws.ws_item_sk = i.i_item_sk
    JOIN call_center cc     ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN ship_mode sm        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t          ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer cust       ON ws.ws_bill_customer_sk = cust.c_customer_sk
),
combined_sales AS (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM web_part
),
agg AS (
    SELECT
        cs.d_year,
        cs.i_category,
        cs.channel,
        COUNT(DISTINCT cs.store_name)                                           AS distinct_stores,
        SUM(cs.sales_amount)                                                    AS total_sales,
        SUM(cs.profit)                                                          AS total_profit,
        CASE WHEN SUM(cs.profit) > 0 THEN 'Positive' ELSE 'Negative' END       AS profit_flag,
        (SELECT AVG(profit) FROM combined_sales cs2 WHERE cs2.i_category = cs.i_category) AS avg_category_profit
    FROM combined_sales cs
    WHERE cs.d_year BETWEEN 1998 AND 2000
      AND cs.sales_amount > 1000
      AND (cs.ship_code = 'AIR' OR cs.ship_code IS NULL)
    GROUP BY GROUPING SETS (
        (cs.d_year, cs.i_category, cs.channel),
        (cs.d_year, cs.i_category),
        (cs.d_year)
    )
)
SELECT
    a.d_year,
    a.i_category,
    a.channel,
    a.distinct_stores,
    a.total_sales,
    a.total_profit,
    a.profit_flag,
    a.avg_category_profit,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM agg a
ORDER BY a.d_year, a.total_sales DESC
LIMIT 100
