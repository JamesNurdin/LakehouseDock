WITH
    store_chan AS (
        SELECT
            'Store' AS channel,
            ca.ca_state AS region,
            i.i_category AS category,
            ss.ss_net_profit AS net_profit,
            ss.ss_net_paid AS net_paid,
            CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type,
            ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_profit DESC) AS rn_store
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE s.s_state = 'CA'                                 -- predicate 1
          AND ca.ca_gmt_offset = -8.00                         -- predicate 2
          AND i.i_brand_id IN (1, 2, 3)                        -- predicate 3
          AND cd.cd_gender = 'M'                               -- predicate 4
          AND r.r_reason_desc LIKE '%defect%'                  -- predicate 5
          AND ss.ss_quantity BETWEEN 1 AND 10                  -- predicate 6
    ),
    catalog_chan AS (
        SELECT
            'Catalog' AS channel,
            cc.cc_country AS region,
            i.i_category AS category,
            cs.cs_net_profit AS net_profit,
            cs.cs_net_paid AS net_paid,
            CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS order_size,
            RANK() OVER (ORDER BY cs.cs_net_profit DESC) AS rank_cat
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cc.cc_division = 3                                 -- predicate 7
          AND cp.cp_type = 'home'                               -- predicate 8
          AND sm.sm_carrier = 'UPS'                             -- predicate 9
          AND w.w_state = 'TX'                                  -- predicate 10
          AND i.i_current_price > 20.00                         -- predicate 11
          AND cd.cd_education_status = 'College'               -- predicate 12
    ),
    web_chan AS (
        SELECT
            'Web' AS channel,
            wp.wp_type AS region,
            i.i_category AS category,
            -wr.wr_return_amt_inc_tax AS net_profit,
            wr.wr_return_amt_inc_tax AS net_paid,
            CASE WHEN wr.wr_return_quantity > 3 THEN 'HighQty' ELSE 'LowQty' END AS return_qty_type,
            DENSE_RANK() OVER (ORDER BY wr.wr_return_amt_inc_tax DESC) AS d_rank_web
        FROM web_returns wr
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wp.wp_type = 'article'                            -- predicate 13
          AND i.i_category = 'Sports'                           -- predicate 14
          AND ca.ca_state = 'NY'                                -- predicate 15
          AND cd.cd_marital_status = 'M'                        -- predicate 16
          AND wr.wr_return_amt_inc_tax > 100.00                -- predicate 17
    ),
    combined AS (
        SELECT * FROM store_chan
        UNION ALL
        SELECT * FROM catalog_chan
        UNION ALL
        SELECT * FROM web_chan
    ),
    agg AS (
        SELECT
            channel,
            region,
            category,
            SUM(net_profit) AS total_profit,
            SUM(net_paid) AS total_paid
        FROM combined
        GROUP BY GROUPING SETS (
            (channel, region, category),
            (channel, region),
            (channel),
            ()
        )
        HAVING SUM(net_profit) > 1000
    )
SELECT
    channel,
    region,
    category,
    total_profit,
    total_paid,
    CASE WHEN total_profit > 5000 THEN 'High' ELSE 'Low' END AS profit_level,
    RANK() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
