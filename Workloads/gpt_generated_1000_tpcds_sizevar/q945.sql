WITH catalog_fact AS (
    SELECT
        cs.cs_sold_date_sk AS d_date_sk,
        d.d_date,
        d.d_year,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cc.cc_call_center_sk,
        cc.cc_state,
        cp.cp_department,
        cp.cp_catalog_number,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND ca_bill.ca_state = 'TX'
),
store_fact AS (
    SELECT
        ss.ss_sold_date_sk AS d_date_sk,
        d2.d_date,
        d2.d_year,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        s.s_state,
        s.s_city,
        ca_ss.ca_state AS ss_addr_state,
        wp.wp_type
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d2.d_date_sk
    WHERE s.s_state = 'TN'
      AND d2.d_month_seq BETWEEN 1 AND 12
      AND wp.wp_type = 'article'
)
SELECT
    COALESCE(c.d_date, s.d_date) AS sale_date,
    COALESCE(c.d_year, s.d_year) AS year,
    COALESCE(c.cc_state, s.s_state) AS state,
    SUM(COALESCE(c.cs_net_paid, 0) + COALESCE(s.ss_net_paid, 0)) AS total_net_paid,
    AVG(COALESCE(c.cs_quantity, 0) + COALESCE(s.ss_quantity, 0)) AS avg_quantity,
    COUNT(DISTINCT COALESCE(c.cs_order_number, s.ss_ticket_number)) AS distinct_transactions,
    CASE
        WHEN SUM(COALESCE(c.cs_quantity, 0) + COALESCE(s.ss_quantity, 0)) > 1000 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    (SELECT MAX(i.inv_quantity_on_hand) FROM inventory i WHERE i.inv_warehouse_sk = 5) AS max_inventory_qty,
    LAG(SUM(COALESCE(c.cs_net_paid, 0) + COALESCE(s.ss_net_paid, 0))) OVER (
        PARTITION BY COALESCE(c.cc_state, s.s_state)
        ORDER BY COALESCE(c.d_date, s.d_date)
    ) AS prev_day_total_net_paid
FROM catalog_fact c
FULL OUTER JOIN store_fact s
    ON c.d_date_sk = s.d_date_sk
LEFT JOIN inventory i ON i.inv_date_sk = COALESCE(c.d_date_sk, s.d_date_sk)
WHERE (c.cp_department = 'Sports' OR s.s_city = 'Nashville')
  AND (c.cc_state = 'CA' OR s.s_state = 'TN')
  AND COALESCE(c.d_year, s.d_year) = 2001
  AND i.inv_warehouse_sk = 5
GROUP BY
    COALESCE(c.d_date, s.d_date),
    COALESCE(c.d_year, s.d_year),
    COALESCE(c.cc_state, s.s_state)
ORDER BY total_net_paid DESC
LIMIT 100
