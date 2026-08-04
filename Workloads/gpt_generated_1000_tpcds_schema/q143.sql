WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_ship_mode_sk,
        ws_web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales
    GROUP BY
        ws_item_sk,
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_ship_mode_sk,
        ws_web_site_sk
),
key_set_2001 AS (
    SELECT cc.cc_call_center_id
    FROM call_center cc
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    WHERE d_open.d_year = 2001
),
key_set_2002 AS (
    SELECT cc.cc_call_center_id
    FROM call_center cc
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    WHERE d_open.d_year = 2002
)
SELECT *
FROM (
    SELECT
        d_sold.d_year AS sales_year,
        i.i_brand,
        sm.sm_type,
        ws_site.web_name,
        cc.cc_name,
        ws_agg.total_sales,
        ws_agg.total_profit,
        ws_agg.order_cnt
    FROM ws_agg
    JOIN item i
        ON ws_agg.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site
        ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_sold
        ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws_agg.ws_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_ws_open
        ON ws_site.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON ws_site.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_sold.d_year = 2001
    GROUP BY
        d_sold.d_year,
        i.i_brand,
        sm.sm_type,
        ws_site.web_name,
        cc.cc_name,
        ws_agg.total_sales,
        ws_agg.total_profit,
        ws_agg.order_cnt
    HAVING ws_agg.total_sales > 10000
) AS q2001
INTERSECT
SELECT *
FROM (
    SELECT
        d_sold.d_year AS sales_year,
        i.i_brand,
        sm.sm_type,
        ws_site.web_name,
        cc.cc_name,
        ws_agg.total_sales,
        ws_agg.total_profit,
        ws_agg.order_cnt
    FROM ws_agg
    JOIN item i
        ON ws_agg.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site
        ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_sold
        ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws_agg.ws_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_ws_open
        ON ws_site.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON ws_site.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_sold.d_year = 2002
    GROUP BY
        d_sold.d_year,
        i.i_brand,
        sm.sm_type,
        ws_site.web_name,
        cc.cc_name,
        ws_agg.total_sales,
        ws_agg.total_profit,
        ws_agg.order_cnt
    HAVING ws_agg.total_sales > 10000
) AS q2002
EXCEPT
SELECT *
FROM (
    SELECT
        d_sold.d_year AS sales_year,
        i.i_brand,
        sm.sm_type,
        ws_site.web_name,
        cc.cc_name,
        ws_agg.total_sales,
        ws_agg.total_profit,
        ws_agg.order_cnt
    FROM ws_agg
    JOIN item i
        ON ws_agg.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site ws_site
        ON ws_agg.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_sold
        ON ws_agg.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws_agg.ws_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_ws_open
        ON ws_site.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON ws_site.web_close_date_sk = d_ws_close.d_date_sk
    WHERE i.i_brand = 'Brand#45'
) AS exclude_brand
ORDER BY total_sales DESC
LIMIT 100
