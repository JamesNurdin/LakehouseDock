WITH
sales_dim AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        w.w_warehouse_name,
        p.p_promo_name,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_education_status
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
),
web_store_full AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity AS ws_quantity,
        ws.ws_sales_price,
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax
    FROM web_sales ws
    FULL OUTER JOIN store_returns sr
        ON ws.ws_item_sk = sr.sr_item_sk
),
intersect_orders AS (
    SELECT cs_order_number AS order_key FROM catalog_sales
    INTERSECT
    SELECT cr_order_number FROM catalog_returns
),
except_tickets AS (
    SELECT sr_ticket_number AS ticket_key FROM store_returns
    EXCEPT
    SELECT ws_order_number FROM web_sales
),
inventory_dim AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        i2.i_item_id,
        i2.i_category
    FROM inventory inv
    JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk
)

SELECT
    sd.i_item_id,
    sd.i_brand,
    sd.i_category,
    COUNT(DISTINCT sd.cs_order_number) AS orders_count,
    SUM(sd.cs_quantity) AS total_quantity_sold,
    SUM(sd.cs_net_paid) AS total_net_paid,
    SUM(sd.cs_net_profit) AS total_profit,
    SUM(wf.ws_sales_price) AS total_web_sales,
    SUM(wf.sr_return_amt_inc_tax) AS total_store_return_amount,
    COUNT(DISTINCT id.inv_item_sk) AS distinct_inventory_items,
    SUM(id.inv_quantity_on_hand) AS total_inventory_on_hand
FROM sales_dim sd
LEFT JOIN web_store_full wf
    ON sd.cs_item_sk = wf.ws_item_sk
LEFT JOIN store_returns sr
    ON sd.cs_item_sk = sr.sr_item_sk
LEFT JOIN inventory_dim id
    ON sd.cs_item_sk = id.inv_item_sk
JOIN intersect_orders io
    ON sd.cs_order_number = io.order_key
LEFT JOIN except_tickets et
    ON sr.sr_ticket_number = et.ticket_key
GROUP BY
    sd.i_item_id,
    sd.i_brand,
    sd.i_category
ORDER BY total_profit DESC
OFFSET 0
LIMIT 100
