WITH sales_agg AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        SUM(cs_ext_sales_price) AS sales_ext_price,
        SUM(cs_net_profit) AS sales_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_wholesale_cost > 30
      AND cs_ship_date_sk BETWEEN 2450840 AND 2450900
    GROUP BY cs_item_sk, cs_order_number
),
returns_agg AS (
    SELECT
        cr_item_sk,
        cr_order_number,
        SUM(cr_return_amount) AS return_amount,
        SUM(cr_net_loss) AS return_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 0
    GROUP BY cr_item_sk, cr_order_number
)
SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(s.sales_ext_price) AS total_sales_price,
    SUM(s.sales_net_profit) AS total_sales_profit,
    SUM(r.return_amount) AS total_return_amount,
    SUM(r.return_net_loss) AS total_return_loss,
    COUNT(DISTINCT s.cs_order_number) AS distinct_sales_orders,
    COUNT(DISTINCT r.cr_order_number) AS distinct_return_orders,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
FROM sales_agg s
JOIN returns_agg r
    ON s.cs_item_sk = r.cr_item_sk
   AND s.cs_order_number = r.cr_order_number
JOIN catalog_sales cs
    ON cs.cs_item_sk = s.cs_item_sk
   AND cs.cs_order_number = s.cs_order_number
JOIN catalog_returns cr
    ON cr.cr_item_sk = r.cr_item_sk
   AND cr.cr_order_number = r.cr_order_number
JOIN item i
    ON i.i_item_sk = s.cs_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
WHERE i.i_brand_id = 5
  AND i.i_current_price BETWEEN 20 AND 100
  AND inv.inv_quantity_on_hand > 10
  AND inv.inv_warehouse_sk IN (6, 15)
  AND ws.ws_sold_date_sk = 2451088
  AND ws.ws_quantity > 1
GROUP BY i.i_item_id, i.i_product_name
ORDER BY total_sales_price DESC
LIMIT 100
