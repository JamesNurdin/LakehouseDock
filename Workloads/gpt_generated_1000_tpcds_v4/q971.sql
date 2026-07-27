WITH
    /* Central date dimension used for all fact tables */
    d AS (
        SELECT *
        FROM tpcds.date_dim
    ),
    /* Promotion date dimensions for store and web promotions */
    d_promo_start_store AS (
        SELECT *
        FROM tpcds.date_dim
    ),
    d_promo_end_store AS (
        SELECT *
        FROM tpcds.date_dim
    ),
    d_promo_start_web AS (
        SELECT *
        FROM tpcds.date_dim
    ),
    d_promo_end_web AS (
        SELECT *
        FROM tpcds.date_dim
    ),
    d_site_open AS (
        SELECT *
        FROM tpcds.date_dim
    ),
    d_site_close AS (
        SELECT *
        FROM tpcds.date_dim
    )
SELECT
    d.d_year                                     AS sale_year,
    ca.ca_state                                   AS customer_state,
    ib.ib_lower_bound                             AS income_band_low,
    ib.ib_upper_bound                             AS income_band_high,
    s.s_state                                     AS store_state,
    w.w_state                                     AS warehouse_state,
    COUNT(DISTINCT ss.ss_ticket_number)          AS store_transactions,
    SUM(ss.ss_net_paid)                           AS store_net_paid,
    SUM(ss.ss_ext_sales_price)                    AS store_ext_sales,
    SUM(ss.ss_ext_discount_amt)                  AS store_discount,
    COUNT(DISTINCT ws.ws_order_number)           AS web_transactions,
    SUM(ws.ws_net_paid)                           AS web_net_paid,
    SUM(ws.ws_ext_sales_price)                    AS web_ext_sales,
    SUM(ws.ws_ext_discount_amt)                  AS web_discount,
    SUM(inv.inv_quantity_on_hand)                AS inventory_on_hand
FROM
    tpcds.store_sales ss
    /* Store‑sales joins */
    JOIN d                ON ss.ss_sold_date_sk      = d.d_date_sk
    JOIN tpcds.household_demographics hd   ON ss.ss_hdemo_sk          = hd.hd_demo_sk
    JOIN tpcds.income_band ib               ON hd.hd_income_band_sk    = ib.ib_income_band_sk
    JOIN tpcds.customer_address ca         ON ss.ss_addr_sk           = ca.ca_address_sk
    JOIN tpcds.store s                     ON ss.ss_store_sk          = s.s_store_sk
    JOIN tpcds.promotion p_store           ON ss.ss_promo_sk          = p_store.p_promo_sk
    JOIN d_promo_start_store dpss          ON p_store.p_start_date_sk = dpss.d_date_sk
    JOIN d_promo_end_store   dpes          ON p_store.p_end_date_sk   = dpes.d_date_sk
    /* Inventory & warehouse (joined through the same date) */
    JOIN tpcds.inventory inv               ON inv.inv_date_sk         = ss.ss_sold_date_sk
    JOIN tpcds.warehouse w                 ON inv.inv_warehouse_sk    = w.w_warehouse_sk
    /* Web‑sales joins (all anchored to the same central date dim) */
    JOIN tpcds.web_sales ws                ON ws.ws_sold_date_sk      = d.d_date_sk
    JOIN tpcds.date_dim d_ship              ON ws.ws_ship_date_sk      = d_ship.d_date_sk
    JOIN tpcds.household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.income_band ib_bill            ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    JOIN tpcds.customer_address ca_bill       ON ws.ws_bill_addr_sk   = ca_bill.ca_address_sk
    JOIN tpcds.promotion p_web                ON ws.ws_promo_sk       = p_web.p_promo_sk
    JOIN d_promo_start_web dpsw               ON p_web.p_start_date_sk = dpsw.d_date_sk
    JOIN d_promo_end_web   dpew               ON p_web.p_end_date_sk   = dpew.d_date_sk
    JOIN tpcds.web_site we                    ON ws.ws_web_site_sk   = we.web_site_sk
    JOIN d_site_open  dso                     ON we.web_open_date_sk = dso.d_date_sk
    JOIN d_site_close dsc                     ON we.web_close_date_sk = dsc.d_date_sk
WHERE
    d.d_year = 2001
    AND ca.ca_country = 'United States'
GROUP BY
    d.d_year,
    ca.ca_state,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    s.s_state,
    w.w_state
ORDER BY
    store_net_paid DESC
LIMIT 100
