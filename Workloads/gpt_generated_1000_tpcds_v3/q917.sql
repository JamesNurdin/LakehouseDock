WITH base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        c.c_customer_id,
        cd.cd_gender,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_amt,
        cr.cr_return_amount,
        ws.ws_ext_ship_cost,
        inv.inv_quantity_on_hand,
        CASE WHEN inv.inv_quantity_on_hand >= 600 THEN 'High Stock' ELSE 'Low Stock' END AS stock_level
    FROM item i
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE ss.ss_sales_price > 20
      AND inv.inv_quantity_on_hand > 500
      AND ws.ws_ext_ship_cost < 2000
),
agg AS (
    SELECT
        i_item_id,
        i_product_name,
        stock_level,
        SUM(ss_sales_price) AS total_sales_price,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(sr_return_amt) AS total_store_return,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(ws_ext_ship_cost) AS total_ship_cost,
        COUNT(DISTINCT c_customer_id) AS distinct_customers
    FROM base
    GROUP BY i_item_id, i_product_name, stock_level
    HAVING SUM(ss_sales_price) > 1000
)
SELECT
    i_item_id,
    i_product_name,
    stock_level,
    total_sales_price,
    total_net_paid,
    total_store_return,
    total_catalog_return,
    total_ship_cost,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY total_net_paid DESC) AS sales_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
