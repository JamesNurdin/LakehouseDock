WITH ss_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_quantity) AS total_qty
    FROM tpcds.store_sales ss TABLESAMPLE BERNOULLI (10)
    WHERE ss.ss_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM tpcds.date_dim d
        WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    )
    GROUP BY ss.ss_item_sk, ss.ss_store_sk, ss.ss_customer_sk
)
SELECT
    d.d_year,
    i.i_category,
    s.s_state,
    c.c_birth_year,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss_agg.total_net_paid) AS total_net_paid,
    AVG(p.p_cost) AS avg_promo_cost,
    SUM(ws.ws_net_paid) AS web_total_net_paid,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(ws.ws_order_number) AS web_orders,
    MAX(ss_agg.total_qty) AS max_quantity_sold,
    (SELECT MAX(ib2.ib_upper_bound) FROM tpcds.income_band ib2) AS max_income_upper,
    colors.color_part
FROM ss_agg
JOIN tpcds.item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN tpcds.store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN tpcds.customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN tpcds.date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
JOIN tpcds.customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN LATERAL (
    SELECT TRIM(color) AS color_part
    FROM UNNEST(split(i.i_color, ',')) AS t(color)
) AS colors ON TRUE
WHERE
    d.d_year = 2001
    AND i.i_category = 'Sports'
    AND s.s_state = 'CA'
    AND c.c_birth_year = 1975
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'M'
GROUP BY
    d.d_year,
    i.i_category,
    s.s_state,
    c.c_birth_year,
    colors.color_part
LIMIT 100
