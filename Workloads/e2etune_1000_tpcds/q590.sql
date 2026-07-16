WITH sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_sold_date_sk AS sales_date_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        (SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_ext_sales_price), 0)) AS profit_margin
    FROM catalog_sales cs
    JOIN inventory i
        ON cs.cs_item_sk = i.inv_item_sk
       AND cs.cs_warehouse_sk = i.inv_warehouse_sk
       AND cs.cs_sold_date_sk = i.inv_date_sk
    WHERE cs.cs_catalog_page_sk IN (159, 23, 244)
      AND cs.cs_ext_tax > 0
      AND cs.cs_ext_sales_price >= 500
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk, cs.cs_sold_date_sk
    HAVING SUM(cs.cs_quantity) > 10
)
SELECT
    item_sk,
    warehouse_sk,
    sales_date_sk,
    total_quantity_sold,
    total_net_paid,
    total_net_profit,
    total_sales_price,
    total_discount,
    total_inventory_on_hand,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY item_sk ORDER BY total_net_profit DESC) AS profit_rank_by_item
FROM sales_agg
ORDER BY profit_margin DESC
LIMIT 100
