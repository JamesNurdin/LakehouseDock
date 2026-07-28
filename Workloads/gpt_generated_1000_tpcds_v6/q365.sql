/* Goal: Analyze combined store and web sales performance for California customers born in the United States in 2001, broken down by store state and promotion, with income‑band filtering, subtotals, a window ranking, and a scalar subquery for the maximum income band upper bound. */
WITH max_income AS (
    SELECT MAX(ib_upper_bound) AS max_ub
    FROM income_band
),
base AS (
    SELECT
        s.s_state                                 AS state,
        p.p_promo_id                              AS promo_id,
        d_sell.d_year                             AS year,
        ss.ss_ext_sales_price                     AS store_sales_price,
        ws.ws_ext_sales_price                     AS web_sales_price,
        wr.wr_return_amt                          AS return_amount,
        ss.ss_ticket_number                       AS store_ticket,
        ws.ws_order_number                        AS web_order
    FROM store_sales ss
    JOIN date_dim d_sell                     ON ss.ss_sold_date_sk = d_sell.d_date_sk
    JOIN time_dim t_sell                     ON ss.ss_sold_time_sk = t_sell.t_time_sk
    JOIN customer c                         ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd           ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd          ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca                ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s                            ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p                        ON ss.ss_promo_sk = p.p_promo_sk
    /* call_center linked through the store closed‑date */
    JOIN date_dim d_cc_closed                ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN call_center cc                     ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    /* web side */
    JOIN web_sales ws                       ON ws.ws_sold_date_sk = d_sell.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp                        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite                     ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p2                       ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN web_returns wr                    ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d_sell.d_date_sk
    /* income band */
    JOIN income_band ib                     ON hd.hd_income_band_sk = ib.ib_income_band_sk
    /* auxiliary date joins for completeness */
    JOIN date_dim d_wp_create                ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN date_dim d_wp_access                ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN date_dim d_promo_start              ON p2.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end                ON p2.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_sell.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_birth_country = 'United States'
      AND hd.hd_income_band_sk IN (2, 3)
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        state,
        promo_id,
        year,
        SUM(store_sales_price) AS total_store_sales,
        SUM(web_sales_price)   AS total_web_sales,
        SUM(return_amount)     AS total_returns,
        COUNT(DISTINCT store_ticket) AS store_txns,
        COUNT(DISTINCT web_order)   AS web_orders
    FROM base
    GROUP BY ROLLUP (state, promo_id, year)
    HAVING SUM(store_sales_price) > 1000
)
SELECT
    state,
    promo_id,
    year,
    total_store_sales,
    total_web_sales,
    total_returns,
    store_txns,
    web_orders,
    (SELECT max_ub FROM max_income) AS max_income_upper,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_store_sales DESC) AS state_rank
FROM agg
ORDER BY state, promo_id
LIMIT 100
