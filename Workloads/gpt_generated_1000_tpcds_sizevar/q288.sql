WITH
    missing_ws_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT ws_order_number
        FROM web_sales
    ),
    joined_data AS (
        SELECT
            cs.cs_order_number,
            cs.cs_item_sk,
            i.i_category,
            i.i_current_price,
            i.i_rec_end_date,
            cs.cs_ext_sales_price,
            w.w_warehouse_sk,
            w.w_state,
            cc.cc_name,
            p.p_promo_name,
            ca_bill.ca_city AS bill_city,
            cd_bill.cd_gender AS bill_gender,
            ws.ws_order_number,
            ws.ws_net_paid,
            wr.wr_return_quantity,
            r.r_reason_desc,
            inv.inv_quantity_on_hand,
            web_site.web_name
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                             AND wr.wr_order_number = ws.ws_order_number
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv
              ON inv.inv_item_sk = i.i_item_sk
             AND inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE cs.cs_order_number IN (SELECT cs_order_number FROM missing_ws_orders)
          AND i.i_current_price > 20
          AND w.w_state = 'CA'
          AND r.r_reason_desc = 'Damaged'
          AND i.i_rec_end_date > DATE '2000-01-01'
          AND inv.inv_quantity_on_hand > 100
    ),
    category_agg AS (
        SELECT
            i_category,
            SUM(cs_ext_sales_price) AS total_ext_sales,
            AVG(i_current_price) AS avg_current_price
        FROM (
            SELECT i_category, cs_ext_sales_price, i_current_price
            FROM joined_data
        ) sub
        GROUP BY i_category
        HAVING SUM(cs_ext_sales_price) > 10000
    ),
    union_groups AS (
        SELECT
            i_category AS category,
            total_ext_sales,
            avg_current_price
        FROM category_agg
        WHERE avg_current_price > 30

        UNION DISTINCT

        SELECT
            i_category AS category,
            SUM(ws_net_paid) AS total_ext_sales,
            AVG(i_current_price) AS avg_current_price
        FROM joined_data
        WHERE ws_net_paid > 0
        GROUP BY i_category
    )
SELECT
    category,
    total_ext_sales,
    avg_current_price,
    (SELECT COUNT(*) FROM reason WHERE r_reason_desc = 'Damaged') AS damaged_reason_count
FROM union_groups
ORDER BY avg_current_price DESC
LIMIT 100
