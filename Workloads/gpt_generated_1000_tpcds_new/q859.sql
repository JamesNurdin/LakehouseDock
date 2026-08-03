WITH
    /* Join all selected tables */
    joined_all AS (
        SELECT
            cs.cs_order_number,
            d.d_year,
            cd.cd_gender,
            p.p_channel_catalog,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_sales_price,
            cr.cr_return_quantity,
            wr.wr_return_quantity,
            i.inv_quantity_on_hand,
            ss.ss_net_paid AS ss_net_paid
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        /* Additional required joins */
        JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
                             AND ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
        LEFT JOIN inventory i ON i.inv_date_sk = d.d_date_sk
                               AND i.inv_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2001
          AND p.p_channel_catalog = 'N'
          AND cd.cd_purchase_estimate > 5000
          AND cs.cs_quantity > (
                SELECT AVG(cs2.cs_quantity)
                FROM catalog_sales cs2
                WHERE cs2.cs_sold_date_sk = 2450816
          )
    ),
    /* EXCEPT – order numbers present in catalog_sales but not in catalog_returns */
    orders_excluding_returns AS (
        SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 5
        EXCEPT
        SELECT cr_order_number FROM catalog_returns WHERE cr_return_quantity > 1
    ),
    /* INTERSECT – order numbers that appear both in store_sales (2001) and web_returns */
    orders_in_both AS (
        SELECT ss_ticket_number FROM store_sales ss
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
        INTERSECT
        SELECT wr_returning_customer_sk FROM web_returns WHERE wr_return_quantity > 0
    ),
    /* UNION – distinct set of order numbers from catalog_sales and web_returns */
    union_orders AS (
        SELECT cs_order_number FROM catalog_sales
        UNION
        SELECT wr_order_number FROM web_returns
    )
SELECT
    ja.d_year,
    ja.cd_gender,
    ja.p_channel_catalog,
    COUNT(DISTINCT ja.cs_order_number)                     AS num_orders,
    SUM(ja.cs_net_paid)                                    AS total_net_paid,
    AVG(ja.cs_quantity)                                    AS avg_quantity,
    MAX(ja.cs_sales_price)                                 AS max_sales_price,
    MIN(ja.inv_quantity_on_hand)                           AS min_inventory,
    COUNT(DISTINCT CASE WHEN ja.cr_return_quantity IS NOT NULL THEN ja.cs_order_number END) AS num_catalog_returns,
    COUNT(DISTINCT CASE WHEN ja.wr_return_quantity IS NOT NULL THEN ja.cs_order_number END) AS num_web_returns,
    SUM(ja.ss_net_paid)                                    AS total_store_net_paid
FROM joined_all ja
WHERE ja.cs_order_number IN (SELECT cs_order_number FROM orders_excluding_returns)
  AND ja.cs_order_number IN (SELECT cs_order_number FROM union_orders)
  AND ja.cs_order_number IN (SELECT ss_ticket_number FROM orders_in_both)
GROUP BY ja.d_year, ja.cd_gender, ja.p_channel_catalog
ORDER BY total_net_paid DESC
LIMIT 100
