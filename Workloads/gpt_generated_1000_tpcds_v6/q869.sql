WITH
    d_sold AS (
        SELECT * FROM date_dim
    ),
    d_ship AS (
        SELECT * FROM date_dim
    ),
    d_wp_create AS (
        SELECT * FROM date_dim
    ),
    d_wp_access AS (
        SELECT * FROM date_dim
    )
SELECT
    c_bill.c_customer_id               AS bill_customer_id,
    p.p_promo_name                     AS promo_name,
    p.p_channel_catalog                AS promo_channel_catalog,
    SUM(cs.cs_net_paid)                AS total_net_paid,
    SUM(cs.cs_net_profit)              AS total_net_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    AVG(inv.inv_quantity_on_hand)      AS avg_inventory_qty,
    MIN(d_sold.d_date)                 AS first_sale_date,
    MAX(d_ship.d_date)                 AS last_ship_date,
    COUNT(DISTINCT r.r_reason_id)      AS distinct_return_reasons
FROM catalog_sales cs
JOIN d_sold               ON cs.cs_sold_date_sk   = d_sold.d_date_sk
JOIN d_ship               ON cs.cs_ship_date_sk   = d_ship.d_date_sk
JOIN customer c_bill      ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer c_ship      ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm        ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN warehouse w         ON cs.cs_warehouse_sk   = w.w_warehouse_sk
JOIN promotion p         ON cs.cs_promo_sk       = p.p_promo_sk
JOIN income_band ib      ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv       ON inv.inv_warehouse_sk = w.w_warehouse_sk
                         AND inv.inv_date_sk     = d_sold.d_date_sk
JOIN store s             ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN web_returns wr     ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN web_page wp         ON wr.wr_web_page_sk   = wp.wp_web_page_sk
JOIN reason r            ON wr.wr_reason_sk     = r.r_reason_sk
JOIN d_wp_create         ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN d_wp_access         ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
JOIN customer c_wp       ON wp.wp_customer_sk   = c_wp.c_customer_sk
JOIN web_site ws         ON ws.web_open_date_sk = d_sold.d_date_sk
GROUP BY
    c_bill.c_customer_id,
    p.p_promo_name,
    p.p_channel_catalog
LIMIT 100
