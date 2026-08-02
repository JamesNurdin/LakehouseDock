WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ca_bill.ca_state,
        ca_ship.ca_city AS ship_city,
        sm.sm_carrier,
        sm.sm_type,
        promo.p_promo_name,
        promo.p_discount_active
    FROM catalog_sales cs
    INNER JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    CROSS JOIN LATERAL (
        SELECT p.p_promo_name, p.p_discount_active
        FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
    ) promo
    WHERE cs.cs_ext_ship_cost > 1000
      AND cs.cs_net_paid_inc_ship > 2000
      AND cs.cs_quantity > 5
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
      AND promo.p_discount_active = 'Y'
      AND sm.sm_carrier = 'AIRBORNE'
      AND ca_bill.ca_state = 'CA'
),
orders_no_return AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT wr.wr_order_number AS order_number
    FROM web_returns wr
),
 sales_with_return_flag AS (
    SELECT
        bs.*,
        CASE WHEN onr.order_number IS NOT NULL THEN 1 ELSE 0 END AS no_return_flag
    FROM base_sales bs
    LEFT JOIN orders_no_return onr
        ON bs.cs_order_number = onr.order_number
),
agg_sales AS (
    SELECT
        cs_ship_mode_sk,
        cs_promo_sk,
        ca_state,
        sm_carrier,
        sm_type,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        SUM(no_return_flag) AS no_return_cnt
    FROM sales_with_return_flag
    GROUP BY cs_ship_mode_sk, cs_promo_sk, ca_state, sm_carrier, sm_type
    HAVING SUM(cs_ext_sales_price) > 5000
       AND COUNT(*) >= 10
)
SELECT
    cs_ship_mode_sk,
    sm_carrier,
    sm_type,
    SUM(total_sales) AS sum_total_sales,
    AVG(total_sales) AS avg_total_sales,
    SUM(sales_cnt) AS sum_sales_cnt,
    SUM(no_return_cnt) AS sum_no_return_cnt
FROM agg_sales
GROUP BY cs_ship_mode_sk, sm_carrier, sm_type
HAVING SUM(total_sales) > 20000
ORDER BY sum_total_sales DESC
LIMIT 100
