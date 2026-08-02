WITH base AS (
    SELECT
        s.s_store_name,
        d.t_hour,
        i.i_brand,
        p_ss.p_promo_name,
        ss.ss_ext_sales_price,
        cs.cs_ext_sales_price,
        ws.ws_ext_sales_price,
        ss.ss_ticket_number,
        cs.cs_order_number,
        ws.ws_order_number,
        i.i_item_sk
    FROM
        store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim d
            ON ss.ss_sold_time_sk = d.t_time_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p_ss
            ON ss.ss_promo_sk = p_ss.p_promo_sk
        JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_sales cs
            ON cs.cs_sold_time_sk = d.t_time_sk
        JOIN promotion p_cs
            ON cs.cs_promo_sk = p_cs.p_promo_sk
        JOIN item i_cs
            ON cs.cs_item_sk = i_cs.i_item_sk
        JOIN ship_mode sm_cs
            ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
        JOIN warehouse w_cs
            ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = d.t_time_sk
        JOIN promotion p_ws
            ON ws.ws_promo_sk = p_ws.p_promo_sk
        JOIN item i_ws
            ON ws.ws_item_sk = i_ws.i_item_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN ship_mode sm_ws
            ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN warehouse w_ws
            ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN web_returns wr
            ON ws.ws_order_number = wr.wr_order_number
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        cs.cs_ext_discount_amt > 1000.00
        AND ss.ss_quantity >= 5
        AND ws.ws_quantity <= 10
        AND i.i_brand = 'Brand#12'
        AND p_ss.p_discount_active = 'Y'
        AND w_cs.w_city = 'Seattle'
        AND d.t_hour BETWEEN 9 AND 17
),
aggregated AS (
    SELECT
        s_store_name,
        t_hour,
        i_brand,
        p_promo_name,
        i_item_sk,
        SUM(COALESCE(ss_ext_sales_price, 0) + COALESCE(cs_ext_sales_price, 0) + COALESCE(ws_ext_sales_price, 0)) AS total_sales_amount,
        COUNT(DISTINCT COALESCE(ss_ticket_number, cs_order_number, ws_order_number)) AS transaction_cnt
    FROM base
    GROUP BY
        s_store_name,
        t_hour,
        i_brand,
        p_promo_name,
        i_item_sk
)
SELECT
    s_store_name,
    t_hour,
    i_brand,
    p_promo_name,
    total_sales_amount,
    transaction_cnt,
    LAG(total_sales_amount) OVER (PARTITION BY s_store_name ORDER BY t_hour) AS prev_hour_sales,
    (SELECT COUNT(*) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = aggregated.i_item_sk) AS catalog_sales_per_item
FROM aggregated
ORDER BY total_sales_amount DESC, s_store_name
LIMIT 100
