WITH first AS (
    SELECT
        ca_bill.ca_state,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cs.cs_net_paid_inc_ship_tax) AS avg_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MIN(cr.cr_fee) AS min_fee,
        MAX(cs.cs_ext_ship_cost) AS max_ship_cost
    FROM catalog_sales cs
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_address ca_ref
      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cs.cs_ship_cdemo_sk = 1502404
      AND cr.cr_warehouse_sk = 11
      AND ca_bill.ca_gmt_offset = -8.00
      AND cs.cs_net_paid_inc_ship_tax > 5000
    GROUP BY ca_bill.ca_state,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END
),
second AS (
    SELECT
        ca_bill.ca_state,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cs.cs_net_paid_inc_ship_tax) AS avg_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MIN(cr.cr_fee) AS min_fee,
        MAX(cs.cs_ext_ship_cost) AS max_ship_cost
    FROM catalog_sales cs
    JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_address ca_ref
      ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cs.cs_ship_cdemo_sk = 599432
      AND cr.cr_warehouse_sk = 7
      AND ca_bill.ca_gmt_offset = -6.00
      AND cs.cs_net_paid_inc_ship_tax BETWEEN 1000 AND 4000
    GROUP BY ca_bill.ca_state,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END
)
SELECT
    state,
    return_category,
    SUM(total_return_amount) AS sum_return_amount,
    AVG(avg_net_paid) AS avg_net_paid,
    SUM(order_cnt) AS total_orders,
    MIN(min_fee) AS overall_min_fee,
    MAX(max_ship_cost) AS overall_max_ship_cost
FROM (
    SELECT ca_state AS state, return_category, total_return_amount, avg_net_paid, order_cnt, min_fee, max_ship_cost
    FROM first
    UNION DISTINCT
    SELECT ca_state AS state, return_category, total_return_amount, avg_net_paid, order_cnt, min_fee, max_ship_cost
    FROM second
) u
GROUP BY state, return_category
ORDER BY sum_return_amount DESC
LIMIT 100
