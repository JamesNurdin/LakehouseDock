/*
Goal: Identify the most profitable states for active promotions by aggregating web sales data, applying multiple filters, handling missing address or promotion information with outer joins, de‑duplicating results via UNION, and exposing rank and overall sales window metrics. The query demonstrates advanced Trino features such as CTE nesting, CASE logic, anti‑semi join, UNION DISTINCT, RIGHT and FULL outer joins, and window functions.
*/
WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_promo_sk,
        ws.ws_ext_sales_price,
        ws.ws_coupon_amt,
        ws.ws_net_profit,
        ca_bill.ca_state      AS bill_state,
        ca_ship.ca_state      AS ship_state,
        p.p_promo_name,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        p.p_response_target,
        p.p_item_sk
    FROM web_sales ws
    RIGHT OUTER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    FULL OUTER JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        ca_bill.ca_gmt_offset BETWEEN -10.00 AND -5.00
        AND ws.ws_coupon_amt > 0
        AND ws.ws_ext_sales_price > 1000
        AND p.p_response_target = 1
        AND p.p_item_sk IN (287899, 207529)
),
agg1 AS (
    SELECT
        bill_state,
        promo_status,
        COUNT(DISTINCT ws_order_number)                     AS orders_cnt,
        SUM(ws_ext_sales_price)                              AS total_sales,
        SUM(ws_net_profit)                                   AS total_profit,
        AVG(ws_coupon_amt)                                   AS avg_coupon
    FROM base
    WHERE
        ws_ext_sales_price > 500
        AND ws_net_profit > 0
        AND ws_coupon_amt >= 0
        AND promo_status = 'Active'
        AND bill_state <> 'UNKNOWN'
    GROUP BY bill_state, promo_status
),
unioned AS (
    SELECT bill_state, promo_status, orders_cnt, total_sales, total_profit, avg_coupon FROM agg1
    UNION
    SELECT bill_state, promo_status, orders_cnt, total_sales, total_profit, avg_coupon FROM agg1 WHERE total_sales < 2000
),
final AS (
    SELECT
        bill_state,
        promo_status,
        SUM(orders_cnt)                         AS total_orders,
        SUM(total_sales)                        AS grand_sales,
        SUM(total_profit)                       AS grand_profit,
        AVG(avg_coupon)                         AS avg_coupon_overall,
        RANK() OVER (ORDER BY SUM(total_sales) DESC) AS sales_rank,
        SUM(SUM(total_sales)) OVER ()           AS overall_sales_sum
    FROM unioned
    GROUP BY bill_state, promo_status
    HAVING SUM(orders_cnt) > 5
)
SELECT *
FROM final
WHERE bill_state NOT IN (
    SELECT ca_state
    FROM customer_address
    WHERE ca_country = 'USA'
)
ORDER BY grand_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
