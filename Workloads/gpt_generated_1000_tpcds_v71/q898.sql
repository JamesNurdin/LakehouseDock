WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d_sold.d_date AS sold_date,
        ws.ws_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        ws.ws_bill_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_web_site_sk,
        s.web_name,
        s.web_country,
        inv.inv_quantity_on_hand,
        cp.cp_department
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = ws.ws_sold_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
       AND cp.cp_end_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND i.i_current_price BETWEEN 10 AND 100
      AND cd.cd_gender = 'M'
      AND s.web_country = 'United States'
      AND inv.inv_quantity_on_hand > 0
      AND cp.cp_department = 'Electronics'
) 
SELECT
    b.ws_order_number,
    b.sold_date,
    b.c_customer_id,
    b.i_item_id,
    b.i_category,
    b.i_current_price,
    b.ws_quantity,
    b.ws_net_paid,
    b.inv_quantity_on_hand,
    RANK() OVER (PARTITION BY b.c_customer_id ORDER BY b.ws_net_paid DESC) AS customer_spend_rank,
    CASE WHEN b.ws_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS purchase_type
FROM base b
WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv2
        JOIN date_dim d2 ON inv2.inv_date_sk = d2.d_date_sk
        WHERE inv2.inv_item_sk = b.ws_item_sk
          AND d2.d_year = 2000
          AND inv2.inv_quantity_on_hand = 0
    )
ORDER BY b.ws_net_paid DESC, b.ws_order_number
LIMIT 100
