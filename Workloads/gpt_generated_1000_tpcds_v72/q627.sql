WITH aggregated AS (
    SELECT
        s.s_store_id               AS store_id,
        d.d_month_seq              AS month_seq,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(sr.sr_return_amt)      AS store_return_amount,
        SUM(wr.wr_return_amt)      AS web_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM tpcds.date_dim d
    LEFT JOIN tpcds.catalog_sales cs          ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_sales ws             ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store_returns sr         ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_returns wr           ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN tpcds.ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN tpcds.customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.inventory i               ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN tpcds.store s                   ON s.s_store_sk = sr.sr_store_sk
    LEFT JOIN tpcds.reason r                  ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN tpcds.time_dim t                ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND s.s_market_id IN (3, 5, 7)
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk > 5
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 1
    GROUP BY s.s_store_id, d.d_month_seq
),
unioned AS (
    SELECT store_id, month_seq, catalog_sales_amount AS metric_value FROM aggregated
    UNION ALL
    SELECT store_id, month_seq, web_sales_amount      AS metric_value FROM aggregated
)
SELECT
    store_id,
    AVG(metric_value) AS avg_metric_value
FROM unioned
GROUP BY store_id
HAVING AVG(metric_value) > 1000
ORDER BY avg_metric_value DESC
LIMIT 100
