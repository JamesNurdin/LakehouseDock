WITH order_union AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 200
    UNION
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
)
SELECT
    c.c_customer_id,
    ib.ib_income_band_sk,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) DESC) AS loss_rank,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    CASE
        WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM
    catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
WHERE
    cr.cr_returned_date_sk BETWEEN 2450900 AND 2451150
    AND cs.cs_ext_ship_cost > 200
    AND hd.hd_dep_count <= 2
    AND ib.ib_upper_bound >= 50000
    AND wp.wp_type = 'dynamic'
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = cs.cs_order_number
    )
    AND cs.cs_order_number IN (SELECT order_number FROM order_union)
GROUP BY
    c.c_customer_id,
    ib.ib_income_band_sk
HAVING
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) > 0
ORDER BY
    total_net_loss DESC
LIMIT 100
