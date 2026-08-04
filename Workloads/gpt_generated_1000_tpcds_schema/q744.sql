WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    cust_return AS (
        SELECT DISTINCT cr_refunded_customer_sk AS c_customer_sk
        FROM catalog_returns
        WHERE cr_return_amount > 500
    ),
    cust_purchase AS (
        SELECT DISTINCT ss_customer_sk AS c_customer_sk
        FROM store_sales
        WHERE ss_net_paid > 0
    ),
    cust_common AS (
        SELECT c_customer_sk FROM cust_return
        INTERSECT
        SELECT c_customer_sk FROM cust_purchase
    ),
    cust_exclusive AS (
        SELECT c_customer_sk FROM cust_return
        EXCEPT
        SELECT c_customer_sk FROM cust_purchase
    ),
    union_sales AS (
        SELECT
            w.w_state AS state,
            p.p_channel_dmail AS channel_dmail,
            SUM(cs.cs_net_paid) AS total_net_paid,
            AVG(cs.cs_net_profit) AS avg_net_profit,
            COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
            CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
        WHERE w.w_state = 'CA'
          AND p.p_channel_dmail = 'Y'
          AND i.i_color = 'Red'
          AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451170
          AND ib.ib_upper_bound > 50000
          AND cr.cr_return_amount > 500
          AND wp.wp_max_ad_count >= 2
          AND cp.cp_department = 'Electronics'
        GROUP BY w.w_state, p.p_channel_dmail
    ),
    union_store AS (
        SELECT
            w.w_state AS state,
            p.p_channel_dmail AS channel_dmail,
            SUM(ss.ss_net_paid) AS total_net_paid,
            AVG(ss.ss_net_profit) AS avg_net_profit,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
            CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN inv_agg ia ON ss.ss_item_sk = ia.inv_item_sk
        JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
        WHERE w.w_state = 'TX'
          AND p.p_channel_dmail = 'N'
          AND i.i_size = 'M'
          AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451170
          AND ib.ib_lower_bound < 30000
          AND s.s_manager = 'William Ward'
        GROUP BY w.w_state, p.p_channel_dmail
    ),
    combined AS (
        SELECT * FROM union_sales
        UNION DISTINCT
        SELECT * FROM union_store
    )
SELECT
    combined.revenue_category,
    COUNT(*) AS cnt,
    SUM(combined.total_net_paid) AS sum_net_paid,
    AVG(combined.avg_net_profit) AS avg_of_avg_profit,
    (SELECT COUNT(*) FROM cust_common) AS common_customer_count,
    (SELECT COUNT(*) FROM cust_exclusive) AS exclusive_customer_count
FROM combined
WHERE combined.revenue_category = 'HIGH'
GROUP BY combined.revenue_category
ORDER BY sum_net_paid DESC
