WITH
    sales_agg AS (
        SELECT ss_customer_sk,
               ss_sold_date_sk,
               sum(ss_net_paid) AS total_net_paid,
               sum(ss_ext_sales_price) AS total_sales_price,
               count(*) AS sales_cnt
        FROM store_sales
        GROUP BY ss_customer_sk, ss_sold_date_sk
    ),
    customers_with_returns AS (
        SELECT cr_refunded_customer_sk AS customer_sk FROM catalog_returns
        EXCEPT
        SELECT ss_customer_sk FROM store_sales
    ),
    warehouses_with_inventory_and_returns AS (
        SELECT inv_warehouse_sk AS warehouse_sk FROM inventory
        INTERSECT
        SELECT cr_warehouse_sk FROM catalog_returns
    ),
    customer_latest_sale AS (
        SELECT c.c_customer_sk,
               ls.latest_sold_date_sk
        FROM customer AS c
        CROSS JOIN LATERAL (
            SELECT ss.ss_sold_date_sk AS latest_sold_date_sk
            FROM store_sales AS ss
            WHERE ss.ss_customer_sk = c.c_customer_sk
            ORDER BY ss.ss_sold_date_sk DESC
            LIMIT 1
        ) AS ls
    )
SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    d_sales.d_date AS sales_date,
    d_return.d_date AS return_date,
    cc.cc_name AS call_center_name,
    r.r_reason_desc,
    w.w_warehouse_name,
    inv.inv_quantity_on_hand,
    sa.total_net_paid,
    sa.total_sales_price,
    sa.sales_cnt,
    d_latest.d_date AS latest_sale_date,
    CASE
        WHEN (SELECT sum(cr2.cr_return_amount)
              FROM catalog_returns AS cr2
              WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk) > 5000 THEN 'High'
        ELSE 'Low'
    END AS return_volume_category,
    RANK() OVER (PARTITION BY hd.hd_buy_potential ORDER BY sa.total_net_paid DESC) AS sales_rank_by_potential,
    (SELECT sum(cr3.cr_return_amount)
     FROM catalog_returns AS cr3
     WHERE cr3.cr_refunded_customer_sk = c.c_customer_sk
       AND cr3.cr_returned_date_sk = d_return.d_date_sk) AS daily_return_amount
FROM
    customers_with_returns cw
    JOIN customer c ON c.c_customer_sk = cw.customer_sk
    LEFT JOIN sales_agg sa ON sa.ss_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_sales ON sa.ss_sold_date_sk = d_sales.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_latest_sale cls ON cls.c_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d_latest ON cls.latest_sold_date_sk = d_latest.d_date_sk
WHERE
    d_sales.d_year = 2001
    AND w.w_state = 'CA'
    AND cc.cc_market_manager = 'John Doe'
    AND hd.hd_buy_potential = '5000-10000'
    AND r.r_reason_id = 'AAAAAAAAEAAAAAAA'
    AND inv.inv_quantity_on_hand > 100
ORDER BY
    sales_rank_by_potential,
    sa.total_net_paid DESC
LIMIT 100
