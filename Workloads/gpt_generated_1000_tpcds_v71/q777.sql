WITH sales_base AS (
    SELECT
        ws.ws_order_number                AS order_number,
        ws.ws_ext_sales_price            AS ext_sales_price,
        ws.ws_net_profit                 AS net_profit,
        c.c_customer_id                  AS customer_id,
        wsit.web_name                    AS web_site_name,
        ca_bill.ca_state                 AS bill_state,
        ca_ship.ca_state                 AS ship_state,
        cd.cd_gender                     AS gender,
        hd.hd_buy_potential              AS buy_potential,
        ib.ib_lower_bound                AS income_lower,
        ib.ib_upper_bound                AS income_upper,
        p.p_promo_name                   AS promo_name,
        sm.sm_type                       AS ship_type,
        wp.wp_type                       AS page_type,
        -- scalar subquery: average profit across the whole fact table
        (SELECT avg(ws2.ws_net_profit) FROM web_sales ws2) AS avg_global_profit
    FROM web_sales ws
    /* date of sale */
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    /* date of shipment */
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    /* billing customer */
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    /* billing address (first alias) */
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    /* shipping address (second alias) */
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    /* customer demographics */
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    /* household demographics */
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    /* income band linked through household demographics */
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* promotion */
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    /* promotion start date */
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    /* promotion end date */
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    /* shipping mode */
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    /* web page */
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    /* web page creation date */
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    /* web page access date */
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    /* web site */
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    /* web site open date */
    JOIN date_dim d_ws_open
        ON wsit.web_open_date_sk = d_ws_open.d_date_sk
    /* web site close date */
    JOIN date_dim d_ws_close
        ON wsit.web_close_date_sk = d_ws_close.d_date_sk
    /* catalog page – we need two date aliases for its start and end dates */
    JOIN date_dim d_cp_start
        ON 1=1                           -- cross‑join to make the alias available
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sold.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM income_band ib2
          WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
            AND ib2.ib_lower_bound >= 50000
      )
)
SELECT
    COALESCE(customer_id, 'ALL') AS customer_id,
    COALESCE(web_site_name, 'ALL') AS web_site_name,
    SUM(ext_sales_price)        AS total_sales,
    SUM(net_profit)             AS total_profit,
    COUNT(DISTINCT order_number) AS order_cnt,
    CASE WHEN SUM(net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    MAX(avg_global_profit)      AS avg_global_profit
FROM sales_base
GROUP BY ROLLUP (customer_id, web_site_name)
HAVING SUM(ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
