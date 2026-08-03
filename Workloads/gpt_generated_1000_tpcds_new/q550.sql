/* goal: Identify high‑volume catalog sales orders (2000‑2002) with detailed product, shipping and customer information, exclude orders that have matching web returns, and then remove any orders that actually do have a web return using EXCEPT. The query also shows inventory on hand, store location, web page type and site name, and expands a two‑element array into separate columns via UNNEST. */
WITH sales_aggr AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        d.d_year,
        d.d_date,
        i.i_category,
        SUM(cs.cs_quantity) AS total_qty,
        AVG(cs.cs_net_paid) AS avg_net_paid,
        cp.cp_department,
        sm.sm_type,
        hd.hd_buy_potential,
        ca.ca_state,
        ARRAY[cp.cp_department, sm.sm_type] AS dept_ship_arr
    FROM catalog_sales cs
    JOIN date_dim d            ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i                ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm          ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca   ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 20
      AND hd.hd_buy_potential = '1000-5000'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        d.d_year,
        d.d_date,
        i.i_category,
        cp.cp_department,
        sm.sm_type,
        hd.hd_buy_potential,
        ca.ca_state,
        ARRAY[cp.cp_department, sm.sm_type]
    HAVING SUM(cs.cs_quantity) > 100
),
returns_aggr AS (
    SELECT cr.cr_order_number,
           SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_order_number
),
inventory_sub AS (
    SELECT inv.inv_item_sk,
           SUM(inv.inv_quantity_on_hand) AS on_hand_qty
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT *
FROM (
    SELECT
        s.d_year,
        s.i_category,
        s.total_qty,
        s.avg_net_paid,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        i.on_hand_qty,
        s.d_date AS sold_date,
        split.dept,
        split.ship_type,
        ss.ss_store_sk,
        wp.wp_type,
        ws.web_name
    FROM sales_aggr s
    LEFT JOIN returns_aggr r      ON s.cs_order_number = r.cr_order_number
    LEFT JOIN inventory_sub i    ON s.cs_item_sk = i.inv_item_sk
    JOIN date_dim d               ON s.cs_sold_date_sk = d.d_date_sk
    JOIN item it                  ON s.cs_item_sk = it.i_item_sk
    JOIN store_sales ss          ON ss.ss_item_sk = it.i_item_sk
                                      AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_page wp             ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws             ON ws.web_open_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(s.dept_ship_arr) WITH ORDINALITY AS u(dept_ship, ord)
    CROSS JOIN LATERAL (
        SELECT
            CASE WHEN u.ord = 1 THEN u.dept_ship END AS dept,
            CASE WHEN u.ord = 2 THEN u.dept_ship END AS ship_type
    ) AS split
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_item_sk = s.cs_item_sk
          AND wr.wr_returned_date_sk = s.cs_sold_date_sk
    )
) AS pos_orders
EXCEPT
SELECT *
FROM (
    SELECT
        s.d_year,
        s.i_category,
        s.total_qty,
        s.avg_net_paid,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        i.on_hand_qty,
        s.d_date AS sold_date,
        split.dept,
        split.ship_type,
        ss.ss_store_sk,
        wp.wp_type,
        ws.web_name
    FROM sales_aggr s
    LEFT JOIN returns_aggr r      ON s.cs_order_number = r.cr_order_number
    LEFT JOIN inventory_sub i    ON s.cs_item_sk = i.inv_item_sk
    JOIN date_dim d               ON s.cs_sold_date_sk = d.d_date_sk
    JOIN item it                  ON s.cs_item_sk = it.i_item_sk
    JOIN store_sales ss          ON ss.ss_item_sk = it.i_item_sk
                                      AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_page wp             ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws             ON ws.web_open_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(s.dept_ship_arr) WITH ORDINALITY AS u(dept_ship, ord)
    CROSS JOIN LATERAL (
        SELECT
            CASE WHEN u.ord = 1 THEN u.dept_ship END AS dept,
            CASE WHEN u.ord = 2 THEN u.dept_ship END AS ship_type
    ) AS split
    WHERE EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_item_sk = s.cs_item_sk
          AND wr.wr_returned_date_sk = s.cs_sold_date_sk
    )
) AS orders_with_web_return
ORDER BY total_qty DESC
LIMIT 100
