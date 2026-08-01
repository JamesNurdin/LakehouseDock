WITH ss_sample AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    cat_sales_agg AS (
        SELECT
            cs_order_number,
            cs_item_sk,
            cs_promo_sk,
            cs_ship_mode_sk,
            cs_warehouse_sk,
            SUM(cs_net_paid)      AS total_cs_net_paid,
            SUM(cs_quantity)      AS total_cs_qty
        FROM catalog_sales
        GROUP BY cs_order_number, cs_item_sk, cs_promo_sk, cs_ship_mode_sk, cs_warehouse_sk
    )
SELECT
    d_sales.d_year,
    p_store.p_promo_name,
    promo_word,
    r_sr.r_reason_desc               AS store_return_reason,
    r_cr.r_reason_desc               AS catalog_return_reason,
    SUM(ss_sample.ss_net_profit)     AS store_total_profit,
    SUM(cr.cr_net_loss)              AS catalog_total_loss,
    COUNT(DISTINCT ss_sample.ss_ticket_number) AS store_txn_cnt,
    ROW_NUMBER() OVER (ORDER BY d_sales.d_year DESC, SUM(ss_sample.ss_net_profit) DESC) AS row_num
FROM ss_sample

/* store‑sales dimension joins */
JOIN date_dim d_sales ON ss_sample.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON ss_sample.ss_sold_time_sk = t_sales.t_time_sk
JOIN promotion p_store ON ss_sample.ss_promo_sk = p_store.p_promo_sk
CROSS JOIN UNNEST(split(p_store.p_promo_name, ' ')) AS u(promo_word)
JOIN customer_demographics cd ON ss_sample.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss_sample.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss_sample.ss_addr_sk = ca.ca_address_sk

/* store‑returns */
JOIN store_returns sr ON ss_sample.ss_ticket_number = sr.sr_ticket_number
                     AND ss_sample.ss_item_sk = sr.sr_item_sk
JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk

/* catalog‑sales aggregation and related dimensions */
JOIN cat_sales_agg ON cat_sales_agg.cs_order_number = sr.sr_ticket_number
                   AND cat_sales_agg.cs_item_sk = sr.sr_item_sk
JOIN promotion p_cat ON cat_sales_agg.cs_promo_sk = p_cat.p_promo_sk
JOIN ship_mode sm ON cat_sales_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cat_sales_agg.cs_warehouse_sk = w.w_warehouse_sk

/* catalog‑returns */
JOIN catalog_returns cr ON cr.cr_order_number = cat_sales_agg.cs_order_number
                        AND cr.cr_item_sk = cat_sales_agg.cs_item_sk
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk

/* web‑returns and web page */
JOIN web_returns wr ON cd.cd_demo_sk = wr.wr_refunded_cdemo_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_web_creation ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
JOIN date_dim d_web_access ON wp.wp_access_date_sk = d_web_access.d_date_sk

/* web site (linked via its open date) */
JOIN web_site wsite ON wsite.web_open_date_sk = d_sales.d_date_sk

GROUP BY
    d_sales.d_year,
    p_store.p_promo_name,
    promo_word,
    r_sr.r_reason_desc,
    r_cr.r_reason_desc

ORDER BY d_sales.d_year DESC, store_total_profit DESC
LIMIT 100
