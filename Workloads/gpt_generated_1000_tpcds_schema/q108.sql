WITH joined AS (
    SELECT
        c.c_customer_id,
        cp.cp_department,
        i.i_brand,
        sm.sm_carrier,
        s.s_state,
        r.r_reason_desc,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        ss.ss_net_profit,
        wp.wp_image_count,
        inv.inv_quantity_on_hand
    FROM
        catalog_sales cs TABLESAMPLE BERNOULLI (10)
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_order_number = cs.cs_order_number
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                             AND ss.ss_customer_sk = c.c_customer_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                               AND sr.sr_customer_sk = c.c_customer_sk
                               AND sr.sr_store_sk = s.s_store_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        cp.cp_department = 'Electronics'
        AND i.i_brand = 'BrandA'
        AND sm.sm_carrier = 'UPS'
        AND s.s_state = 'CA'
        AND wp.wp_image_count > 2
        AND inv.inv_quantity_on_hand > 0
        AND EXISTS (
            SELECT 1 FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_link_count > 5
        )
),
agg AS (
    SELECT
        c_customer_id,
        r_reason_desc,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM joined
    GROUP BY c_customer_id, r_reason_desc
)
SELECT
    r_reason_desc,
    AVG(total_profit) AS avg_profit,
    SUM(total_sales) AS sum_sales,
    SUM(total_returns) AS sum_returns,
    (SELECT COUNT(DISTINCT c_customer_id) FROM joined) AS distinct_customers
FROM agg
WHERE total_sales > 1000
GROUP BY r_reason_desc
HAVING AVG(total_profit) > 0
ORDER BY avg_profit DESC
LIMIT 100
