WITH sales_agg AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        cp.cp_department,
        sm.sm_carrier,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p               ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.date_dim d                ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t                ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_wholesale_cost > 20
      AND d.d_year = 2001
      AND sm.sm_carrier = 'AIRBORNE'
    GROUP BY d.d_date_sk, d.d_year, cp.cp_department, sm.sm_carrier
)
SELECT
    sa.d_year,
    sa.cp_department,
    sa.sm_carrier,
    sa.total_sales,
    COUNT(DISTINCT i.inv_warehouse_sk) AS warehouse_cnt,
    SUM(sr.sr_return_amt)                AS total_return_amt,
    AVG(ws.ws_net_profit)                AS avg_web_profit
FROM sales_agg sa
JOIN tpcds.inventory i          ON i.inv_date_sk = sa.d_date_sk
JOIN tpcds.store_returns sr    ON sr.sr_returned_date_sk = sa.d_date_sk
JOIN tpcds.reason r            ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.web_sales ws        ON ws.ws_sold_date_sk = sa.d_date_sk
JOIN tpcds.web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr      ON wr.wr_order_number = ws.ws_order_number
JOIN tpcds.customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE sa.total_sales > 100000
  AND i.inv_quantity_on_hand > 0
  AND c.c_customer_sk IN (
        SELECT sr_customer_sk FROM tpcds.store_returns WHERE sr_return_quantity > 1
    )
GROUP BY sa.d_year, sa.cp_department, sa.sm_carrier, sa.total_sales
ORDER BY sa.total_sales DESC
LIMIT 100
