WITH base_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        d_sold.d_year,
        d_sold.d_quarter_seq,
        d_ship.d_month_seq,
        i.i_category,
        cd_bill.cd_gender AS bill_gender,
        COALESCE(cd_ship.cd_gender, 'UNKNOWN') AS ship_gender,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        wp.wp_type AS web_page_type,
        t.t_hour,
        CASE
            WHEN ws.ws_net_profit > 0 THEN 'Profit'
            WHEN ws.ws_net_profit = 0 THEN 'BreakEven'
            ELSE 'Loss'
        END AS profit_flag
    FROM web_sales ws
    INNER JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    INNER JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    INNER JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    LEFT JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    agg.d_year,
    agg.i_category,
    agg.profit_flag,
    agg.total_sales,
    agg.total_profit,
    agg.order_cnt
FROM (
    SELECT
        d_year,
        i_category,
        profit_flag,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM base_sales
    WHERE d_year BETWEEN 1999 AND 2001
    GROUP BY d_year, i_category, profit_flag
    UNION ALL
    SELECT
        d_year,
        i_category,
        profit_flag,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM base_sales
    WHERE d_year = 2000 AND i_category = 'Sports'
    GROUP BY d_year, i_category, profit_flag
) AS agg
ORDER BY agg.total_sales DESC
LIMIT 100
