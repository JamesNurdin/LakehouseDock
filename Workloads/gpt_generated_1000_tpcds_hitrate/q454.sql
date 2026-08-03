WITH cat_data AS (
    SELECT
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'Catalog' AS sales_type,
        cs.cs_net_paid AS sales_amount,
        cs.cs_quantity AS quantity,
        cd.cd_gender,
        w.w_warehouse_sk,
        w.w_state AS warehouse_state,
        w.w_city AS warehouse_city,
        inv.inv_quantity_on_hand AS inv_qty
    FROM catalog_sales cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN inventory inv            ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_discount_amt > 0
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND inv.inv_quantity_on_hand > 10
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451060
),
web_data AS (
    SELECT
        c.c_customer_id,
        concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        'Web' AS sales_type,
        ws.ws_net_paid AS sales_amount,
        ws.ws_quantity AS quantity,
        cd.cd_gender,
        w.w_warehouse_sk,
        w.w_state AS warehouse_state,
        w.w_city AS warehouse_city,
        inv.inv_quantity_on_hand AS inv_qty
    FROM web_sales ws
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we              ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inventory inv            ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_quantity > 1
      AND ws.ws_ext_discount_amt > 0
      AND we.web_country = 'United States'
      AND we.web_state = 'CA'
      AND inv.inv_quantity_on_hand > 10
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451060
),
combined_sales AS (
    SELECT * FROM cat_data
    UNION DISTINCT
    SELECT * FROM web_data
),
agg_sales AS (
    SELECT
        cs.c_customer_id      AS customer_id,
        cs.sales_type,
        SUM(cs.sales_amount)  AS total_sales,
        SUM(cs.quantity)      AS total_quantity,
        MAX(cs.inv_qty)       AS max_inv_qty,
        MIN(cs.warehouse_state) AS warehouse_state,
        MIN(cs.warehouse_city)  AS warehouse_city,
        MIN(cs.w_warehouse_sk)  AS warehouse_sk,
        CASE WHEN MIN(cs.cd_gender) = 'M' THEN 'Male' ELSE 'Female' END AS gender_desc
    FROM combined_sales cs
    GROUP BY cs.c_customer_id, cs.sales_type
)
SELECT
    a.customer_id,
    a.sales_type,
    a.total_sales,
    a.total_quantity,
    a.max_inv_qty,
    a.warehouse_state,
    a.warehouse_city,
    a.gender_desc,
    ROW_NUMBER() OVER (PARTITION BY a.sales_type ORDER BY a.total_sales DESC) AS sales_rank
FROM agg_sales a
WHERE a.total_sales > 1000
  AND a.total_quantity >= 5
  AND a.max_inv_qty > 10
  AND a.warehouse_state = 'CA'
  AND a.gender_desc = 'Male'
  AND EXISTS (
        SELECT 1 FROM inventory inv2
        WHERE inv2.inv_warehouse_sk = a.warehouse_sk
          AND inv2.inv_quantity_on_hand > 0
    )
ORDER BY a.total_sales DESC, sales_rank
LIMIT 100
