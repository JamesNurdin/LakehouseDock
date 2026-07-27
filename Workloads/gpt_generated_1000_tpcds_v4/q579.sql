WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss AS store_return_loss,
        cs.cs_quantity,
        cs.cs_net_paid AS catalog_net_paid,
        cr.cr_return_quantity,
        cr.cr_net_loss AS catalog_return_loss,
        wr.wr_return_quantity,
        wr.wr_net_loss AS web_return_loss,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        p.p_promo_name,
        rs.r_reason_desc AS store_reason_desc,
        rc.r_reason_desc AS catalog_reason_desc,
        rw.r_reason_desc AS web_reason_desc,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        td.t_hour,
        td.t_am_pm
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason rs ON sr.sr_reason_sk = rs.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN reason rc ON cr.cr_reason_sk = rc.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN reason rw ON wr.wr_reason_sk = rw.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND c.c_preferred_cust_flag = 'Y'
      AND ib.ib_lower_bound >= 50000
      AND inv.inv_quantity_on_hand > 0
      AND td.t_hour BETWEEN 12 AND 14
)
SELECT
    s_store_name,
    i_category,
    i_brand,
    t_hour,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(store_return_loss) AS total_store_return_loss,
    SUM(catalog_net_paid) AS total_catalog_sales,
    SUM(catalog_return_loss) AS total_catalog_return_loss,
    SUM(web_return_loss) AS total_web_return_loss,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(ib_lower_bound) AS min_income_lower,
    MAX(ib_upper_bound) AS max_income_upper
FROM base
GROUP BY s_store_name, i_category, i_brand, t_hour
ORDER BY total_store_sales DESC
LIMIT 100
