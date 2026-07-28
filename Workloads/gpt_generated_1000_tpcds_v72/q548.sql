/* goal: Rank items by net profit for the year 2002, combining sales and returns across catalog, store, and web channels, while applying several business filters and using a scalar subquery for average catalog price per item */
WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d_cs.d_year,
        d_cs.d_month_seq,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(cr.cr_return_amount) AS catalog_returns,
        SUM(sr.sr_return_amt) AS store_returns,
        (SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) -
         SUM(cr.cr_return_amount) - SUM(sr.sr_return_amt)) AS net_total,
        (
            SELECT AVG(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_catalog_price
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* catalog returns */
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    /* store sales */
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    /* store returns */
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    /* web sales */
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    /* inventory */
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    /* additional date joins for promotion and web page */
    JOIN date_dim d_promo_start ON p_cs.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end   ON p_cs.p_end_date_sk   = d_promo_end.d_date_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access   ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
    /* store closed date */
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE
    d_cs.d_year = 2002
    AND ib.ib_upper_bound > 50000
    AND sm_ws.sm_type = 'AIR'
    AND p_cs.p_discount_active = 'Y'
    AND ca.ca_gmt_offset = -5.00
    AND inv.inv_quantity_on_hand > 100
GROUP BY
    i.i_item_id,
    i.i_product_name,
    d_cs.d_year,
    d_cs.d_month_seq,
    i.i_item_sk
)
SELECT
    sagg.i_item_id,
    sagg.i_product_name,
    sagg.d_year,
    sagg.d_month_seq,
    sagg.catalog_sales,
    sagg.store_sales,
    sagg.web_sales,
    sagg.catalog_returns,
    sagg.store_returns,
    sagg.net_total,
    sagg.avg_catalog_price,
    CASE WHEN sagg.net_total > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    RANK() OVER (PARTITION BY sagg.d_year ORDER BY sagg.net_total DESC) AS sales_rank
FROM sales_agg sagg
ORDER BY sagg.net_total DESC, sagg.i_item_id
LIMIT 100
