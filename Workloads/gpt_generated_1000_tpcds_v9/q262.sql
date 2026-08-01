WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date_sk,
        s.s_store_id,
        s.s_market_manager,
        wsit.web_site_id,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        cp.cp_catalog_page_sk,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ca.ca_city,
        t.t_hour
    FROM date_dim d
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site wsit
        ON wsit.web_open_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_market_manager = 'Charles Bartley'
      AND sm.sm_type = 'AIR'
      AND cd.cd_gender = 'M'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_order_number = ws.ws_order_number
      )
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          JOIN date_dim d2
            ON cr2.cr_returned_date_sk = d2.d_date_sk
          WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
            AND d2.d_year = 2001
            AND d2.d_month_seq = 12
      )
)
SELECT
    d_year,
    s_store_id,
    s_market_manager,
    web_site_id,
    cp_catalog_page_sk,
    CASE
        WHEN SUM(ws_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_category,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_quantity) AS total_quantity,
    COUNT(DISTINCT ws_order_number) AS order_count,
    SUM(CASE WHEN ws_net_profit > 0 THEN ws_net_profit ELSE 0 END) AS total_positive_profit,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    AVG(cr_return_amount) AS avg_return_amount,
    (
        SELECT AVG(cr_sub.cr_return_amount)
        FROM catalog_returns cr_sub
        WHERE cr_sub.cr_catalog_page_sk = cp_catalog_page_sk
          AND cr_sub.cr_returned_date_sk = d_date_sk
    ) AS avg_return_amount_per_page_date
FROM base
GROUP BY
    d_year,
    s_store_id,
    s_market_manager,
    web_site_id,
    cp_catalog_page_sk,
    d_date_sk
ORDER BY total_net_profit DESC
LIMIT 100
