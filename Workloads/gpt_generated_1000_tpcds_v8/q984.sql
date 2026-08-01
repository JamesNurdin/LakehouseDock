WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
orders_without_returns AS (
    SELECT cs_order_number
    FROM sampled_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
),
base_agg AS (
    SELECT
        cc.cc_name,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_category,
        AVG(price_calc.discounted_price) AS avg_discounted_price
    FROM sampled_sales cs
    RIGHT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp_sales
        ON cs.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN orders_without_returns owr
        ON cs.cs_order_number = owr.cs_order_number
    CROSS JOIN LATERAL (
        SELECT i.i_current_price * 0.8 AS discounted_price
    ) AS price_calc
    WHERE cs.cs_sold_date_sk IS NOT NULL
    GROUP BY
        cc.cc_name,
        i.i_category
)
SELECT
    ba.cc_name,
    ba.i_category,
    ba.total_net_profit,
    ba.order_cnt,
    ba.profit_category,
    ba.avg_discounted_price,
    SUM(ba.total_net_profit) OVER (PARTITION BY ba.cc_name ORDER BY ba.total_net_profit
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    RANK() OVER (ORDER BY ba.total_net_profit DESC) AS profit_rank
FROM base_agg ba
ORDER BY ba.total_net_profit DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY
