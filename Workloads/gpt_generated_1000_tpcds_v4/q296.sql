WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ss.ss_ext_sales_price,
        wss.ws_ext_sales_price,
        i.inv_quantity_on_hand,
        c.c_customer_id,
        ib.ib_lower_bound,
        cd.cd_marital_status,
        cc.cc_tax_percentage,
        wh.w_state,
        cp.cp_type
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales wss
        ON wss.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.warehouse wh
        ON wh.w_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    LEFT JOIN tpcds.income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = ss.ss_cdemo_sk
    LEFT JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = ss.ss_addr_sk
    LEFT JOIN tpcds.customer c
        ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN tpcds.reason r
        ON r.r_reason_sk = sr.sr_reason_sk
    WHERE d.d_year = 2001
      AND wh.w_state = 'CA'
      AND ib.ib_lower_bound >= 100000
      AND cd.cd_marital_status = 'M'
      AND cp.cp_type = 'C'
)
SELECT
    base.d_year,
    base.d_month_seq,
    SUM(base.ss_ext_sales_price) AS store_sales_total,
    SUM(base.ws_ext_sales_price) AS web_sales_total,
    SUM(base.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT base.c_customer_id) AS distinct_customers,
    AVG(base.ib_lower_bound) AS avg_income_lower_bound,
    MAX(base.cc_tax_percentage) AS max_call_center_tax_pct
FROM base
GROUP BY
    base.d_year,
    base.d_month_seq
ORDER BY
    store_sales_total DESC
LIMIT 100
