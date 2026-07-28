WITH sales_agg AS (
    SELECT
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit)                                 AS total_sales_profit,
        COUNT(*)                                              AS sales_cnt
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    /* filter predicates */
    WHERE i.i_current_price > 50
      AND cd.cd_dep_employed_count >= 1
      AND p.p_discount_active = 'Y'
    GROUP BY ss.ss_customer_sk
),
returns_agg AS (
    SELECT
        wr.wr_returning_customer_sk               AS customer_sk,
        SUM(wr.wr_net_loss)                       AS total_return_loss,
        COUNT(*)                                   AS return_cnt
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    /* filter predicates */
    WHERE wr.wr_return_quantity > 0
      AND cd.cd_dep_college_count = 0
      AND i.i_category = 'Electronics'
    GROUP BY wr.wr_returning_customer_sk
),
inventory_agg AS (
    SELECT
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    /* filter predicates */
    WHERE w.w_country = 'United States'
      AND inv.inv_quantity_on_hand > 100
    GROUP BY i.i_item_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    cd.cd_gender,
    i.i_product_name,
    i.i_category,
    p.p_promo_name,
    sa.total_sales_profit,
    ra.total_return_loss,
    (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit,
    ROW_NUMBER() OVER (
        ORDER BY (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) DESC
    ) AS profit_rank,
    ia.total_on_hand,
    w.w_city          AS warehouse_city,
    w.w_state         AS warehouse_state
FROM sales_agg sa
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN returns_agg ra ON c.c_customer_sk = ra.customer_sk
LEFT JOIN inventory_agg ia ON i.i_item_sk = ia.i_item_sk
/* Bring a warehouse row for the same item through inventory to satisfy the join requirement */
LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_current_price BETWEEN 60 AND 200
  AND cd.cd_gender = 'M'
  AND w.w_state = 'CA'
