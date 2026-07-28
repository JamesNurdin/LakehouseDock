WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        td.t_hour,
        rs.sr_return_quantity,
        cs.cs_ship_mode_sk,
        sm.sm_ship_mode_id,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_order_number,
        wr.wr_return_quantity,
        wsite.web_name
    FROM store_sales ss
    JOIN time_dim td                 ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c                  ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd    ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd   ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib              ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns rs      ON ss.ss_item_sk = rs.sr_item_sk
                                      AND ss.ss_ticket_number = rs.sr_ticket_number
    LEFT JOIN catalog_sales cs      ON ss.ss_customer_sk = cs.cs_bill_customer_sk
                                      AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_sales ws          ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr        ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN web_site wsite         ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE ss.ss_quantity > 1                               -- predicate 1
      AND ss.ss_ext_sales_price > 100.00                    -- predicate 2
      AND ib.ib_lower_bound >= 20000                        -- predicate 3
      AND ib.ib_upper_bound <= 150000                       -- predicate 4
      AND cd.cd_gender = 'M'                                 -- predicate 5
      AND td.t_hour BETWEEN 9 AND 17                        -- predicate 6
),
agg_by_customer_hour AS (
    SELECT
        c_customer_id,
        t_hour,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit)      AS avg_profit,
        COUNT(*)                AS sales_cnt
    FROM base_sales
    GROUP BY c_customer_id, t_hour
)
SELECT
    c_customer_id,
    t_hour,
    total_sales,
    avg_profit,
    sales_cnt
FROM agg_by_customer_hour
WHERE total_sales > 1000.00
ORDER BY total_sales DESC, c_customer_id
LIMIT 100
