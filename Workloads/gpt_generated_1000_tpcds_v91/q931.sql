SELECT
    swd.cs_sold_date_sk,
    swd.w_warehouse_name,
    swd.income_category,
    sum(swd.cs_net_paid) AS total_net_paid,
    sum(swd.cs_net_profit) AS total_net_profit,
    sum(swd.cs_quantity) AS total_quantity,
    sum(COALESCE(swd.cr_return_amount, 0)) AS total_return_amount,
    sum(swd.return_cnt) AS total_return_transactions,
    avg(swd.avg_item_sales_price) AS avg_item_price_over_orders,
    count(*) AS orders_count,
    count(DISTINCT swd.wp_web_page_sk) AS web_page_visits
FROM (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c_bill.c_customer_sk AS bill_customer_sk,
        c_bill.c_first_name,
        c_bill.c_last_name,
        cd_bill.cd_gender,
        cd_bill.cd_marital_status,
        hd_bill.hd_income_band_sk,
        ib_bill.ib_lower_bound,
        ib_bill.ib_upper_bound,
        w.w_warehouse_name,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        r.r_reason_desc,
        CASE
            WHEN ib_bill.ib_lower_bound >= 150000 THEN 'High Income'
            WHEN ib_bill.ib_lower_bound >= 100000 THEN 'Medium Income'
            ELSE 'Low Income'
        END AS income_category,
        (
            SELECT avg(cs2.cs_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = cs.cs_item_sk
        ) AS avg_item_sales_price,
        cr_stats.return_cnt,
        cr_stats.total_return_amount,
        cr_stats.max_return_amount,
        wp.wp_web_page_sk
    FROM catalog_sales cs
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib_bill
        ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    LEFT JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN LATERAL (
        SELECT
            count(*) AS return_cnt,
            sum(cr2.cr_return_amount) AS total_return_amount,
            max(cr2.cr_return_amount) AS max_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
    ) AS cr_stats ON true
    FULL OUTER JOIN web_page wp
        ON wp.wp_customer_sk = c_bill.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450099
) swd
GROUP BY
    swd.cs_sold_date_sk,
    swd.w_warehouse_name,
    swd.income_category
ORDER BY
    total_net_paid DESC
LIMIT 100
