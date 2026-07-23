WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_state,
        sm.sm_carrier,
        ca.ca_gmt_offset,
        cd.cd_gender,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
        CASE
            WHEN SUM(cs.cs_ext_discount_amt) > 0 THEN 'HasDiscount'
            ELSE 'NoDiscount'
        END AS discount_flag
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
            AND ss.ss_cdemo_sk = cd.cd_demo_sk
            AND ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN store_returns sr
            ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_cdemo_sk = cd.cd_demo_sk
            AND sr.sr_addr_sk = ca.ca_address_sk
            AND sr.sr_store_sk = s.s_store_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN web_page wp
            ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1210
        AND s.s_state = 'CA'
        AND sm.sm_carrier = 'UPS'
        AND ca.ca_gmt_offset = -5.00
        AND cd.cd_gender = 'M'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_state,
        sm.sm_carrier,
        ca.ca_gmt_offset,
        cd.cd_gender
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    s_state,
    sm_carrier,
    ca_gmt_offset,
    cd_gender,
    total_catalog_net_paid,
    total_store_net_paid,
    total_return_amt,
    catalog_order_cnt,
    store_ticket_cnt,
    avg_catalog_discount,
    discount_flag,
    (total_catalog_net_paid + total_store_net_paid - total_return_amt) AS net_revenue
FROM sales_summary
ORDER BY net_revenue DESC
LIMIT 100
