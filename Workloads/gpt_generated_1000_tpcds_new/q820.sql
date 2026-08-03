WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        t.t_hour,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        cust.c_first_name,
        cust.c_last_name,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        w.w_city,
        w.w_state,
        w.w_zip
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND cc.cc_gmt_offset BETWEEN -5 AND 0
      AND i.i_current_price > 50
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
),
enriched AS (
    SELECT
        b.*,
        ss.ss_quantity            AS ss_quantity,
        ss.ss_net_paid            AS ss_net_paid,
        sr.sr_return_amt          AS sr_return_amt,
        inv.inv_quantity_on_hand  AS inv_quantity_on_hand,
        wp.wp_url                 AS wp_url,
        wr.wr_return_amt          AS wr_return_amt,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM tpcds.catalog_sales cs2
            WHERE cs2.cs_item_sk = b.cs_item_sk
        )                         AS avg_item_profit
    FROM base b
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = b.cs_item_sk
       AND ss.ss_sold_date_sk = b.cs_sold_date_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_item_sk = b.cs_item_sk
       AND inv.inv_warehouse_sk = b.cs_warehouse_sk
    LEFT JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = b.cs_bill_customer_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_item_sk = b.cs_item_sk
       AND wr.wr_refunded_customer_sk = b.cs_bill_customer_sk
       AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE ss.ss_quantity > 0
      AND sr.sr_return_amt IS NOT NULL
      AND inv.inv_quantity_on_hand > 0
      AND wp.wp_type = 'HOME'
      AND wr.wr_return_amt > 0
)
SELECT
    e.d_year                     AS year,
    e.i_category                 AS category,
    e.i_brand                    AS brand,
    SUM(e.cs_net_paid)           AS total_sales,
    SUM(e.sr_return_amt)         AS total_store_returns,
    AVG(e.avg_item_profit)       AS avg_item_profit
FROM enriched e
GROUP BY e.d_year, e.i_category, e.i_brand
HAVING SUM(e.cs_net_paid) > 10000
UNION
SELECT
    e.d_year                     AS year,
    e.i_category                 AS category,
    e.i_brand                    AS brand,
    SUM(e.cs_net_paid)           AS total_sales,
    SUM(e.sr_return_amt)         AS total_store_returns,
    AVG(e.avg_item_profit)       AS avg_item_profit
FROM enriched e
WHERE e.w_city = 'Los Angeles'
GROUP BY e.d_year, e.i_category, e.i_brand
HAVING SUM(e.cs_net_paid) > 5000
EXCEPT
SELECT
    sub.year,
    sub.category,
    sub.brand,
    sub.total_sales,
    sub.total_store_returns,
    sub.avg_item_profit
FROM (
    SELECT
        e.d_year                     AS year,
        e.i_category                 AS category,
        e.i_brand                    AS brand,
        SUM(e.cs_net_paid)           AS total_sales,
        SUM(e.sr_return_amt)         AS total_store_returns,
        AVG(e.avg_item_profit)       AS avg_item_profit
    FROM enriched e
    GROUP BY e.d_year, e.i_category, e.i_brand
    HAVING SUM(e.cs_net_paid) < 20000
) sub
ORDER BY total_sales DESC
LIMIT 100
