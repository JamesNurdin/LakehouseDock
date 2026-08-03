WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_category,
           i_brand,
           i_current_price
    FROM tpcds.item
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    WHERE i_category = 'Electronics'
      AND i_current_price BETWEEN 100 AND 500
),
joined_data AS (
    SELECT
        s.s_store_name               AS s_store_name,
        s.s_state                    AS store_state,
        i.i_category                 AS i_category,
        i.i_brand                    AS i_brand,
        SUM(ws.ws_ext_sales_price)   AS total_sales,
        SUM(ws.ws_net_profit)        AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_level,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM filtered_items i
    JOIN tpcds.web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd_ws
        ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN tpcds.income_band ib_ws
        ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
    JOIN tpcds.customer_address ca_ws
        ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN tpcds.customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_brand = 'Brand#12'
      AND ca_ws.ca_state = 'CA'
      AND we.web_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND w.w_city = 'Los Angeles'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
      AND EXISTS (
          SELECT 1
          FROM tpcds.web_returns wr2
          WHERE wr2.wr_order_number = ws.ws_order_number
            AND wr2.wr_return_amt > 0
      )
    GROUP BY
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_brand
)
SELECT
    s_store_name,
    store_state,
    i_category,
    i_brand,
    total_sales,
    total_profit,
    avg_discount,
    order_cnt,
    profit_level,
    rn
FROM joined_data
WHERE rn <= 5
ORDER BY s_store_name, rn
LIMIT 100
