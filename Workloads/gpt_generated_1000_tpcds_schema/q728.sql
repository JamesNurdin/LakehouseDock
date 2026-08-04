WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
item_inventory AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_category,
           inv.inv_quantity_on_hand
    FROM item i
    JOIN sampled_inventory inv
      ON i.i_item_sk = inv.inv_item_sk
),
date_filtered AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq,
           d_current_month,
           d_date
    FROM date_dim
    WHERE d_year = 2001
      AND d_current_month = 'Y'
),
catalog_sales_filtered AS (
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_quantity,
           cs_net_paid,
           cs_ext_discount_amt,
           cs_bill_cdemo_sk
    FROM catalog_sales
    WHERE cs_wholesale_cost > 20.00
),
store_sales_filtered AS (
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_quantity,
           ss_net_paid,
           ss_ext_discount_amt,
           ss_cdemo_sk,
           ss_store_sk
    FROM store_sales
    WHERE ss_list_price < 200.00
),
intersect_items AS (
    SELECT cs_item_sk AS item_sk FROM catalog_sales
    INTERSECT
    SELECT ss_item_sk FROM store_sales
)
SELECT
    d.d_date,
    i.i_category,
    s.s_store_name,
    SUM(COALESCE(cs.cs_net_paid, 0))               AS total_catalog_net_paid,
    SUM(COALESCE(ss.ss_net_paid, 0))               AS total_store_net_paid,
    AVG(COALESCE(cs.cs_ext_discount_amt, 0))       AS avg_catalog_discount,
    inv_tot.total_quantity_on_hand,
    cd_bill.cd_gender,
    cd_ship.cd_gender AS ship_gender
FROM date_filtered d
FULL OUTER JOIN catalog_sales_filtered cs
    ON cs.cs_sold_date_sk = d.d_date_sk
FULL OUTER JOIN store_sales_filtered ss
    ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN customer_demographics cd_bill
    ON cd_bill.cd_demo_sk = cs.cs_bill_cdemo_sk
LEFT JOIN customer_demographics cd_ship
    ON cd_ship.cd_demo_sk = ss.ss_cdemo_sk
LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN item i
    ON (cs.cs_item_sk = i.i_item_sk OR ss.ss_item_sk = i.i_item_sk)
CROSS JOIN LATERAL (
    SELECT SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM sampled_inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
) AS inv_tot
WHERE i.i_item_sk IN (SELECT item_sk FROM intersect_items)
  AND cs.cs_quantity > (
        SELECT MAX(cs_quantity)
        FROM catalog_sales
        WHERE cs_item_sk = cs.cs_item_sk
    )
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
GROUP BY
    d.d_date,
    i.i_category,
    s.s_store_name,
    inv_tot.total_quantity_on_hand,
    cd_bill.cd_gender,
    cd_ship.cd_gender
ORDER BY total_catalog_net_paid DESC
LIMIT 100
