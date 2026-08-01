-- Goal: Analyze combined store and web sales performance by store, year, month, gender, and sales category, with subtotals, running totals, and filters on division, department, state, gender and sales amounts.
WITH joined_data AS (
    SELECT
        cc.cc_division_name                AS cc_division_name,
        cp.cp_department                  AS cp_department,
        c.c_customer_id                    AS c_customer_id,
        cd.cd_gender                       AS cd_gender,
        cd.cd_education_status             AS cd_education_status,
        d.d_year                           AS d_year,
        d.d_month_seq                      AS d_month_seq,
        d.d_date                           AS d_date,
        t.t_hour                           AS t_hour,
        s.s_store_name                     AS s_store_name,
        s.s_state                          AS s_state,
        w.w_warehouse_name                 AS w_warehouse_name,
        w.w_state                          AS w_state,
        sm.sm_type                         AS ship_mode_type,
        ss.ss_ticket_number                AS ss_ticket_number,
        ss.ss_ext_sales_price              AS store_ext_sales_price,
        ss.ss_net_paid                     AS store_net_paid,
        ws.ws_ext_sales_price              AS web_ext_sales_price,
        ws.ws_net_paid                     AS web_net_paid,
        i.inv_quantity_on_hand             AS inv_quantity_on_hand,
        r.r_reason_desc                    AS r_reason_desc,
        CASE WHEN ss.ss_ext_sales_price + ws.ws_ext_sales_price > 20000 THEN 'High' ELSE 'Normal' END AS sales_category,
        store_agg.total_store_sales        AS store_total_sales_lateral,
        (SELECT MAX(sr2.sr_return_amt_inc_tax)
         FROM store_returns sr2
         WHERE sr2.sr_ticket_number = ss.ss_ticket_number) AS max_return_amt_inc_tax
    FROM
        date_dim d
        INNER JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN (
            inventory i
            FULL OUTER JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
        ) ON i.inv_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                                 AND ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
        LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
        CROSS JOIN LATERAL (
            SELECT SUM(ss2.ss_ext_sales_price) AS total_store_sales
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = s.s_store_sk
        ) AS store_agg
    WHERE
        d.d_year = 2001
        AND cd.cd_gender = 'F'
        AND s.s_state = 'CA'
        AND ws.ws_net_paid > 1000
        AND cc.cc_division_name = 'able'
        AND cp.cp_department = 'Health'
),
aggregated AS (
    SELECT
        cc_division_name,
        cp_department,
        s_store_name,
        d_year,
        d_month_seq,
        sales_category,
        COUNT(DISTINCT c_customer_id)                         AS num_customers,
        SUM(store_ext_sales_price)                            AS total_store_sales,
        SUM(web_ext_sales_price)                              AS total_web_sales,
        SUM(store_ext_sales_price + web_ext_sales_price)     AS total_combined_sales,
        AVG(inv_quantity_on_hand)                             AS avg_inventory_qty,
        MAX(max_return_amt_inc_tax)                           AS max_return_amt,
        MAX(store_total_sales_lateral)                        AS total_sales_by_store
    FROM joined_data
    GROUP BY ROLLUP (cc_division_name, cp_department, s_store_name, d_year, d_month_seq, sales_category)
)
SELECT
    cc_division_name,
    cp_department,
    s_store_name,
    d_year,
    d_month_seq,
    sales_category,
    num_customers,
    total_store_sales,
    total_web_sales,
    total_combined_sales,
    avg_inventory_qty,
    max_return_amt,
    total_sales_by_store,
    SUM(total_store_sales) OVER (
        PARTITION BY s_store_name
        ORDER BY d_year, d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_store_total_sales
FROM aggregated
ORDER BY
    cc_division_name NULLS FIRST,
    cp_department NULLS FIRST,
    s_store_name NULLS FIRST,
    d_year,
    d_month_seq,
    sales_category
LIMIT 100
