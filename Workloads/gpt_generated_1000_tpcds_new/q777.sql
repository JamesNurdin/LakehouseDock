WITH agg_customer AS (
    SELECT
        c.c_customer_id,
        c.c_customer_sk,
        cc.cc_call_center_id,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
        SUM(sr.sr_return_amt) AS returns_total,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        COUNT(DISTINCT cs.cs_promo_sk) AS distinct_promos,
        SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS positive_profit
    FROM tpcds.time_dim t
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    FULL OUTER JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN tpcds.web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND cc.cc_state = 'CA'
      AND ib.ib_upper_bound > 80000
      AND cs.cs_net_profit > 0
      AND sr.sr_return_quantity > 0
    GROUP BY
        c.c_customer_id,
        c.c_customer_sk,
        cc.cc_call_center_id
),
intersect_customers AS (
    SELECT c_customer_id FROM agg_customer WHERE store_sales_total > 1000
    INTERSECT
    SELECT c_customer_id FROM agg_customer WHERE catalog_sales_total > 2000
)
SELECT
    ic.c_customer_id,
    a.store_sales_total,
    a.catalog_sales_total,
    a.returns_total,
    a.distinct_pages,
    a.distinct_promos,
    a.positive_profit,
    l.cs_count,
    CASE
        WHEN a.store_sales_total > a.catalog_sales_total THEN 'StoreHigher'
        ELSE 'CatalogHigher'
    END AS sales_comparison
FROM intersect_customers ic
JOIN agg_customer a
    ON ic.c_customer_id = a.c_customer_id
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS cs_count
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = a.c_customer_sk
) l
ORDER BY a.store_sales_total DESC
LIMIT 100
