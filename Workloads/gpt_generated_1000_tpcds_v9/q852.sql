WITH sales_return_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_item_sk,
        sr.sr_reason_sk,
        sr.sr_returned_date_sk,
        SUM(ss.ss_net_paid) AS sales_net_paid,
        SUM(ss.ss_net_profit) AS sales_net_profit,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
    GROUP BY
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_item_sk,
        sr.sr_reason_sk,
        sr.sr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    ca_sales.ca_city,
    ca_sales.ca_state,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    cp.cp_catalog_number,
    inv.inv_quantity_on_hand,
    r.r_reason_desc,
    wp.wp_url,
    ws.web_name,
    SUM(sra.sales_net_paid) AS total_sales_net_paid,
    SUM(sra.sales_net_profit) AS total_sales_net_profit,
    SUM(sra.total_return_amt) AS total_return_amount,
    SUM(sra.total_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(sra.sales_net_profit) DESC) AS profit_rank
FROM sales_return_agg sra
JOIN store s
    ON sra.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON sra.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_return
    ON sra.sr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN customer c
    ON sra.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON sra.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_sales
    ON sra.ss_addr_sk = ca_sales.ca_address_sk
JOIN inventory inv
    ON d_sales.d_date_sk = inv.inv_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sales.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN reason r
    ON sra.sr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp_check
    WHERE wp_check.wp_customer_sk = c.c_customer_sk
)
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    ca_sales.ca_city,
    ca_sales.ca_state,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_department,
    cp.cp_catalog_number,
    inv.inv_quantity_on_hand,
    r.r_reason_desc,
    wp.wp_url,
    ws.web_name
ORDER BY total_sales_net_profit DESC
LIMIT 100
