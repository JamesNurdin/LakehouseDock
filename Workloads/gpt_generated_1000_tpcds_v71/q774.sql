WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
    sa.s_store_name,
    d_ret.d_year AS return_year,
    SUM(sa.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sa.ss_net_profit) - SUM(sr.sr_net_loss) - SUM(cr.cr_net_loss) AS net_contribution,
    ROW_NUMBER() OVER (PARTITION BY sa.s_store_name ORDER BY SUM(sa.ss_net_profit) DESC) AS profit_rank
FROM sales_agg sa
-- Store returns and its related dimensions
JOIN store_returns sr
    ON sa.ss_ticket_number = sr.sr_ticket_number
   AND sa.ss_item_sk = sr.sr_item_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN store s_ret
    ON sr.sr_store_sk = s_ret.s_store_sk
JOIN customer c_ret
    ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
-- Catalog returns and its related dimensions
JOIN catalog_returns cr
    ON sa.ss_customer_sk = cr.cr_refunded_customer_sk
JOIN date_dim d_cat
    ON cr.cr_returned_date_sk = d_cat.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cat
    ON cr.cr_reason_sk = r_cat.r_reason_sk
-- Web site information linked via the sales surrogate date key
JOIN web_site ws
    ON ws.web_open_date_sk = sa.ss_sold_date_sk
JOIN date_dim d_web
    ON ws.web_open_date_sk = d_web.d_date_sk
WHERE d_ret.d_year = 2001
GROUP BY
    sa.s_store_name,
    d_ret.d_year
ORDER BY net_contribution DESC
LIMIT 100
