WITH
    sales_base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_quantity,
            cs.cs_ext_ship_cost,
            cs.cs_net_paid_inc_ship,
            cs.cs_net_profit,
            cs.cs_wholesale_cost,
            cs.cs_list_price,
            cs.cs_promo_sk,
            hd.hd_demo_sk,
            hd.hd_buy_potential,
            hd.hd_dep_count,
            ARRAY[cs.cs_wholesale_cost, cs.cs_list_price] AS cost_array,
            p.p_promo_name
        FROM
            tpcds.catalog_sales cs
            JOIN tpcds.household_demographics hd
                ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
            LEFT JOIN tpcds.promotion p
                ON cs.cs_promo_sk = p.p_promo_sk
        WHERE
            cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915
            AND cs.cs_quantity > 1
            AND cs.cs_ext_ship_cost > 500
            AND hd.hd_dep_count IN (2, 4, 8)
            AND hd.hd_buy_potential = '1001-5000'
    ),
    returns_agg AS (
        SELECT
            wr.wr_order_number,
            SUM(wr.wr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt
        FROM
            tpcds.web_returns wr
            JOIN tpcds.household_demographics hd
                ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE
            wr.wr_returned_date_sk BETWEEN 2451910 AND 2451915
            AND wr.wr_return_amt > 50
            AND hd.hd_dep_count IN (2, 4, 8)
            AND hd.hd_buy_potential = '1001-5000'
        GROUP BY
            wr.wr_order_number
    ),
    sales_with_returns AS (
        SELECT
            sb.cs_order_number,
            sb.cs_sold_date_sk,
            sb.cs_quantity,
            sb.cs_ext_ship_cost,
            sb.cs_net_paid_inc_ship,
            sb.cs_net_profit,
            sb.hd_demo_sk,
            sb.hd_buy_potential,
            sb.hd_dep_count,
            sb.cost_array,
            sb.p_promo_name,
            COALESCE(ra.total_return_amt, 0) AS total_return_amt,
            COALESCE(ra.return_cnt, 0) AS return_cnt,
            (sb.cs_net_paid_inc_ship - COALESCE(ra.total_return_amt, 0)) AS net_revenue
        FROM
            sales_base sb
            LEFT JOIN returns_agg ra
                ON sb.cs_order_number = ra.wr_order_number
    )
SELECT
    swr.hd_buy_potential,
    CASE WHEN u.cost_idx = 1 THEN 'wholesale_cost' ELSE 'list_price' END AS cost_type,
    SUM(u.cost_value) AS total_cost,
    AVG(swr.net_revenue) AS avg_net_revenue,
    COUNT(DISTINCT swr.cs_order_number) AS distinct_orders,
    (SELECT COUNT(*) FROM tpcds.promotion p WHERE p.p_channel_tv = 'Y') AS total_tv_promotions
FROM
    sales_with_returns swr
    CROSS JOIN UNNEST(swr.cost_array) WITH ORDINALITY AS u(cost_value, cost_idx)
WHERE
    swr.cs_ext_ship_cost > 600
    AND swr.return_cnt <= 2
    AND swr.cs_quantity <= 5
    AND swr.cs_net_profit > 0
GROUP BY
    swr.hd_buy_potential,
    CASE WHEN u.cost_idx = 1 THEN 'wholesale_cost' ELSE 'list_price' END
HAVING
    SUM(u.cost_value) > 1000
ORDER BY
    swr.hd_buy_potential,
    cost_type
