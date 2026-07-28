WITH base AS (
    SELECT
        s.s_store_name                AS s_store_name,
        s.s_state                     AS s_state,
        d_sales.d_year                AS d_year,
        p.p_promo_name                AS p_promo_name,
        i.i_category                  AS i_category,
        ss.ss_net_paid                AS ss_net_paid,
        ss.ss_sales_price             AS ss_sales_price,
        sr.sr_return_amt              AS sr_return_amt,
        cr.cr_return_amount           AS cr_return_amount,
        ws.ws_net_paid                AS ws_net_paid,
        c.c_customer_sk               AS c_customer_sk,
        i.i_brand                     AS i_brand,
        p.p_discount_active           AS p_discount_active,
        cc.cc_state                   AS cc_state
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    /* catalog returns */
    JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr
      ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    /* store returns */
    JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr
      ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN reason r2
      ON sr.sr_reason_sk = r2.r_reason_sk
    /* web sales */
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
      ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
      ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN customer c2
      ON wp.wp_customer_sk = c2.c_customer_sk
    /* income band */
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d_sales.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'NY'
)
SELECT
    s_store_name,
    s_state,
    d_year,
    p_promo_name,
    i_category,
    SUM(ss_net_paid)               AS total_store_sales,
    SUM(sr_return_amt)             AS total_store_returns,
    SUM(cr_return_amount)          AS total_catalog_returns,
    SUM(ws_net_paid)               AS total_web_sales,
    COUNT(DISTINCT c_customer_sk)  AS distinct_customers,
    AVG(ss_sales_price)            AS avg_sales_price,
    MIN(d_year)                    AS min_year,
    MAX(d_year)                    AS max_year,
    SUM(SUM(ss_net_paid)) OVER (PARTITION BY s_state) AS state_total_sales,
    RANK() OVER (ORDER BY SUM(ss_net_paid) DESC)       AS sales_rank
FROM base
GROUP BY s_store_name, s_state, d_year, p_promo_name, i_category
HAVING SUM(ss_net_paid) > 100000
ORDER BY total_store_sales DESC
LIMIT 100
