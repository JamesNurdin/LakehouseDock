WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_state,
        cc.cc_call_center_id,
        cc.cc_gmt_offset,
        w.w_city,
        ss.ss_net_paid,
        ss.ss_quantity,
        cs.cs_net_paid,
        cs.cs_quantity,
        sr.sr_net_loss,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        wp.wp_type
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site webs
        ON webs.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
      AND s.s_state = 'CA'
      AND cc.cc_gmt_offset > -5
      AND w.w_city = 'Seattle'
      AND cs.cs_quantity > 5
      AND ss.ss_net_paid > 1000
      AND inv.inv_quantity_on_hand > 0
      AND r.r_reason_desc = 'Customer Not Satisfied'
),
store_agg AS (
    SELECT
        d_year,
        s_store_id,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(sr_net_loss) AS total_store_returns,
        SUM(wr_net_loss) AS total_web_returns,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT r_reason_desc) AS distinct_return_reasons,
        COUNT(DISTINCT wp_type) AS distinct_page_types,
        (SUM(ss_net_paid) + SUM(cs_net_paid) - SUM(sr_net_loss) - SUM(wr_net_loss)) AS net_total
    FROM base
    GROUP BY d_year, s_store_id
),
callcenter_agg AS (
    SELECT
        d_year,
        cc_call_center_id,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(sr_net_loss) AS total_store_returns,
        SUM(wr_net_loss) AS total_web_returns,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT r_reason_desc) AS distinct_return_reasons,
        COUNT(DISTINCT wp_type) AS distinct_page_types,
        (SUM(ss_net_paid) + SUM(cs_net_paid) - SUM(sr_net_loss) - SUM(wr_net_loss)) AS net_total
    FROM base
    GROUP BY d_year, cc_call_center_id
)
SELECT DISTINCT
    d_year,
    entity_id,
    total_store_sales,
    total_catalog_sales,
    net_total,
    distinct_return_reasons,
    distinct_page_types
FROM (
    SELECT
        d_year,
        s_store_id AS entity_id,
        total_store_sales,
        total_catalog_sales,
        net_total,
        distinct_return_reasons,
        distinct_page_types
    FROM store_agg
    WHERE net_total > 20000
    UNION
    SELECT
        d_year,
        cc_call_center_id AS entity_id,
        total_store_sales,
        total_catalog_sales,
        net_total,
        distinct_return_reasons,
        distinct_page_types
    FROM callcenter_agg
    WHERE net_total > 20000
) final
ORDER BY net_total DESC
LIMIT 100
