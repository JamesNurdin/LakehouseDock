WITH
store_agg AS (
    SELECT
        s.s_store_id AS store_id,
        cc.cc_manager AS manager,
        d_sold.d_year AS year,
        d_sold.d_month_seq AS month_seq,
        t_sold.t_hour AS hour,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_ext_discount_amt) AS discount_amt,
        COUNT(*) AS txn_cnt,
        'store' AS channel
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND s.s_street_name = 'Willow'
      AND s.s_company_name = 'Unknown'
      AND t_sold.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity > 10
    GROUP BY CUBE (s.s_store_id, cc.cc_manager, d_sold.d_year, d_sold.d_month_seq, t_sold.t_hour)
    HAVING SUM(ss.ss_net_paid) > 1000
),
web_agg AS (
    SELECT
        NULL AS store_id,
        cc.cc_manager AS manager,
        d_ws_sold.d_year AS year,
        d_ws_sold.d_month_seq AS month_seq,
        t_ws_sold.t_hour AS hour,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_ext_discount_amt) AS discount_amt,
        COUNT(*) AS txn_cnt,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_ws_sold.d_date_sk
    WHERE d_ws_sold.d_year = 2002
      AND ws.ws_quantity > 20
      AND t_ws_sold.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_ship_cost > 100
    GROUP BY CUBE (cc.cc_manager, d_ws_sold.d_year, d_ws_sold.d_month_seq, t_ws_sold.t_hour)
    HAVING SUM(ws.ws_net_paid) > 1000
),
combined_agg AS (
    SELECT * FROM store_agg
    UNION DISTINCT
    SELECT * FROM web_agg
),
expanded AS (
    SELECT
        ca.store_id,
        ca.manager,
        ca.year,
        ca.month_seq,
        ca.hour,
        ca.net_paid,
        ca.discount_amt,
        ca.txn_cnt,
        ca.channel,
        attr_elem AS attribute
    FROM combined_agg ca
    CROSS JOIN UNNEST(array[ca.store_id, ca.manager]) AS t(attr_elem)
)
SELECT
    store_id,
    manager,
    year,
    month_seq,
    hour,
    attribute,
    SUM(net_paid) AS total_net_paid,
    SUM(discount_amt) AS total_discount,
    SUM(txn_cnt) AS total_txns,
    CASE WHEN SUM(net_paid) > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
    (SUM(net_paid) / (
        SELECT total_year_net FROM (
            SELECT SUM(ss2.ss_net_paid) AS total_year_net
            FROM store_sales ss2
            JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2002
        ) t
    )) AS net_paid_share
FROM expanded
GROUP BY CUBE (store_id, manager, year, month_seq, hour, attribute)
HAVING SUM(net_paid) > 5000
ORDER BY total_net_paid DESC, sales_category
LIMIT 100
