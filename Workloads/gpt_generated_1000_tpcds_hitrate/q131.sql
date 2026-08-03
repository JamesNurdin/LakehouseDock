WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_weekend,
        cd.cd_gender,
        cd.cd_education_status,
        i.i_brand,
        i.i_category,
        cc.cc_name,
        s.s_state,
        t.t_hour,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        ws.ws_net_paid,
        ws.ws_quantity,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.time_dim t
        ON t.t_time_sk = cs.cs_sold_time_sk
    LEFT JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN tpcds.item i
        ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    LEFT JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = cs.cs_bill_addr_sk
    LEFT JOIN tpcds.reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    WHERE d.d_year = 2001
      AND d.d_weekend = 'N'
      AND cd.cd_education_status = 'Advanced Degree'
      AND i.i_brand = 'Brand#12'
      AND cc.cc_name = 'Call Center 1'
)
SELECT
    d_year,
    d_month_seq,
    d_weekend,
    cd_gender,
    cd_education_status,
    i_brand,
    i_category,
    cc_name,
    s_state,
    t_hour,
    SUM(cs_net_paid)            AS total_catalog_sales,
    SUM(ws_net_paid)            AS total_web_sales,
    SUM(cr_return_amount)       AS total_returns,
    SUM(inv_quantity_on_hand)   AS total_inventory,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_net_paid) DESC) AS sales_rank
FROM base
WHERE EXISTS (
    SELECT 1 FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_order_number = base.cs_order_number
)
GROUP BY CUBE (
    d_year,
    d_month_seq,
    d_weekend,
    cd_gender,
    cd_education_status,
    i_brand,
    i_category,
    cc_name,
    s_state,
    t_hour
)
HAVING SUM(cs_net_paid) > 0
ORDER BY total_catalog_sales DESC
LIMIT 100
