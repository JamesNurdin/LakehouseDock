WITH sales_inv AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        d_sold.d_year AS sold_year,
        d_sold.d_quarter_name AS sold_quarter,
        d_ship.d_week_seq AS ship_week_seq,
        d_ship.d_holiday AS ship_holiday,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 1998
      AND d_sold.d_holiday = 'N'
      AND d_ship.d_holiday = 'Y'
      AND d_ship.d_qoy = 2
      AND d_ship.d_week_seq BETWEEN 10 AND 20
      AND inv.inv_warehouse_sk IN (5, 13, 15)
      AND inv.inv_quantity_on_hand >= 300
      AND cs.cs_net_paid >= 500
      AND cs.cs_quantity BETWEEN 1 AND 10
),
agg AS (
    SELECT
        sold_year,
        sold_quarter,
        inv_warehouse_sk,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cs_quantity) AS avg_quantity,
        MIN(inv_quantity_on_hand) AS min_qty_on_hand,
        MAX(inv_quantity_on_hand) AS max_qty_on_hand
    FROM sales_inv
    GROUP BY sold_year, sold_quarter, inv_warehouse_sk
)
SELECT
    sold_year,
    sold_quarter,
    inv_warehouse_sk,
    orders_cnt,
    total_net_paid,
    avg_quantity,
    min_qty_on_hand,
    max_qty_on_hand,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn
FROM agg
ORDER BY total_net_paid DESC
