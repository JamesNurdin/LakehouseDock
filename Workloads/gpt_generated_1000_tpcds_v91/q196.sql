WITH
base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_ext_discount_amt AS cs_ext_discount_amt,
        cs.cs_net_profit AS cs_net_profit,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_mkt_id,
        w.w_state,
        ws.ws_net_paid_inc_tax,
        ws.ws_ext_ship_cost,
        wr.wr_account_credit,
        wr.wr_refunded_cash,
        r.r_reason_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        td.t_hour,
        td.t_meal_time
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        cc.cc_manager = 'Jason Brito'
        AND cc.cc_mkt_id IN (1, 3, 5)
        AND ws.ws_net_paid_inc_tax > 1000
        AND ws.ws_ext_ship_cost > 2000
        AND wr.wr_account_credit > 100
        AND td.t_hour BETWEEN 9 AND 17
),

intersect_orders AS (
    SELECT cs.cs_order_number AS order_id
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
    INTERSECT
    SELECT ws.ws_order_number AS order_id
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
)

SELECT
    agg.grouping_key,
    agg.grouping_type,
    SUM(agg.sales_amount) AS total_sales,
    AVG(agg.discount_amount) AS avg_discount,
    COUNT(DISTINCT agg.order_id) AS distinct_orders,
    MIN(agg.profit) AS min_profit,
    MAX(agg.profit) AS max_profit,
    (SELECT COUNT(*) FROM intersect_orders) AS intersect_order_cnt,
    (SELECT COUNT(DISTINCT wr2.wr_refunded_customer_sk)
     FROM web_returns wr2
     WHERE wr2.wr_refunded_cash > 200) AS high_refund_customers
FROM (
    SELECT
        cc_name AS grouping_key,
        'CallCenter' AS grouping_type,
        cs_ext_sales_price AS sales_amount,
        cs_ext_discount_amt AS discount_amount,
        cs_order_number AS order_id,
        cs_net_profit AS profit
    FROM base
    UNION
    SELECT
        w_state AS grouping_key,
        'Warehouse' AS grouping_type,
        cs_ext_sales_price AS sales_amount,
        cs_ext_discount_amt AS discount_amount,
        cs_order_number AS order_id,
        cs_net_profit AS profit
    FROM base
) AS agg
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr3
    WHERE wr3.wr_order_number = agg.order_id
      AND wr3.wr_refunded_cash > 200
)
AND agg.order_id IN (SELECT order_id FROM intersect_orders)
GROUP BY agg.grouping_key, agg.grouping_type
ORDER BY total_sales DESC
LIMIT 100
