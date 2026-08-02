WITH combined AS (
    /* Store channel branch */
    SELECT
        d1.d_year AS year,
        w.w_country AS country,
        p.p_promo_id AS promo_id,
        ss.ss_net_paid AS net_sales_amount,
        COALESCE(sr.sr_net_loss, 0) AS net_loss_amount,
        ss.ss_net_profit AS net_profit_amount
    FROM store_sales ss
    INNER JOIN date_dim d1
        ON ss.ss_sold_date_sk = d1.d_date_sk
    INNER JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d1.d_date_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d1.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d2
        ON sr.sr_returned_date_sk = d2.d_date_sk
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_name
        FROM promotion p2
        WHERE p2.p_start_date_sk = d1.d_date_sk
        LIMIT 1
    ) AS pl

    UNION DISTINCT

    /* Web channel branch */
    SELECT
        d1.d_year AS year,
        w.w_country AS country,
        p.p_promo_id AS promo_id,
        ws.ws_net_paid AS net_sales_amount,
        COALESCE(wr.wr_net_loss, 0) AS net_loss_amount,
        ws.ws_net_profit AS net_profit_amount
    FROM web_sales ws
    INNER JOIN date_dim d1
        ON ws.ws_sold_date_sk = d1.d_date_sk
    INNER JOIN web_site sit
        ON ws.ws_web_site_sk = sit.web_site_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = ws.ws_item_sk
           AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN date_dim d2
        ON wr.wr_returned_date_sk = d2.d_date_sk
    CROSS JOIN LATERAL (
        SELECT p2.p_promo_name
        FROM promotion p2
        WHERE p2.p_start_date_sk = d1.d_date_sk
        LIMIT 1
    ) AS pl
)
SELECT
    year,
    country,
    promo_id,
    SUM(net_sales_amount) AS total_sales,
    SUM(net_loss_amount) AS total_loss,
    SUM(net_profit_amount) AS total_profit
FROM combined
GROUP BY year, country, promo_id
ORDER BY total_sales DESC
LIMIT 100
