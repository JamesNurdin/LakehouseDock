WITH sampled_sales AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        ws.ws_net_paid,
        ws.ws_quantity,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        i.i_rec_start_date,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_education_status,
        ca.ca_state,
        ca.ca_city,
        w.w_warehouse_name,
        wp.wp_url,
        wp.wp_image_count
    FROM sampled_sales ws
    JOIN item i                ON ws.ws_item_sk      = i.i_item_sk
    JOIN customer c            ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk   = cd.cd_demo_sk
    JOIN customer_address ca   ON ws.ws_bill_addr_sk    = ca.ca_address_sk
    JOIN warehouse w           ON ws.ws_warehouse_sk    = w.w_warehouse_sk
    JOIN web_page wp           ON ws.ws_web_page_sk    = wp.wp_web_page_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_image_count   > 2
      AND ca.ca_state          = 'CA'
      AND cd.cd_gender         = 'M'
),
aggregated AS (
    SELECT
        c_customer_id,
        i_item_id,
        i_category,
        SUM(ws_net_paid)   AS total_net_paid,
        SUM(ws_quantity)   AS total_quantity,
        AVG(i_current_price) AS avg_item_price,
        RANK() OVER (PARTITION BY i_category ORDER BY SUM(ws_net_paid) DESC) AS category_customer_rank
    FROM joined_data
    GROUP BY c_customer_id, i_item_id, i_category
    HAVING SUM(ws_net_paid) > 1000
),
subquery1 AS (
    SELECT c_customer_id, i_item_id
    FROM aggregated
    WHERE category_customer_rank = 1
),
subquery2 AS (
    SELECT c_customer_id, i_item_id
    FROM aggregated
    WHERE avg_item_price > (SELECT AVG(i_current_price) FROM item)
),
final_set AS (
    SELECT
        a.c_customer_id,
        a.i_item_id,
        a.i_category,
        a.total_net_paid,
        a.total_quantity,
        a.category_customer_rank
    FROM aggregated a
    WHERE (a.c_customer_id, a.i_item_id) IN (
            SELECT c_customer_id, i_item_id FROM subquery1
            INTERSECT
            SELECT c_customer_id, i_item_id FROM subquery2
          )
      AND a.c_customer_id NOT IN (
            SELECT c_customer_id FROM customer WHERE c_preferred_cust_flag = 'N'
          )
)
SELECT *
FROM final_set
ORDER BY total_net_paid DESC
LIMIT 100
