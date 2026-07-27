WITH base AS (
    SELECT
        w.w_warehouse_id AS w_warehouse_id,
        w.w_state AS w_state,
        d.d_year AS d_year,
        sm.sm_type AS sm_type,
        cd.cd_gender AS cd_gender,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_ext_discount_amt AS cs_ext_discount_amt,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_order_number AS cs_order_number,
        i.inv_quantity_on_hand AS inv_quantity_on_hand,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        (
            SELECT SUM(i2.inv_quantity_on_hand)
            FROM inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
        ) AS total_inventory_warehouse
    FROM date_dim d
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
       AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cd.cd_gender = 'M'
      AND cs.cs_quantity > 5
      AND i.inv_quantity_on_hand > 0
)
SELECT
    w_warehouse_id,
    w_state,
    d_year,
    sm_type,
    cd_gender,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_category,
    SUM(cs_net_paid) AS total_sales,
    AVG(cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    SUM(sr_net_loss) AS total_store_loss,
    SUM(wr_net_loss) AS total_web_loss,
    MIN(inv_quantity_on_hand) AS min_inventory,
    MAX(inv_quantity_on_hand) AS max_inventory,
    total_inventory_warehouse
FROM base
GROUP BY
    w_warehouse_id,
    w_state,
    d_year,
    sm_type,
    cd_gender,
    total_inventory_warehouse
HAVING SUM(cs_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
