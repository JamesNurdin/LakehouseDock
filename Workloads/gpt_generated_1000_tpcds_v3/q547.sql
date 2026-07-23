WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        i.i_item_sk,
        i.i_item_id,
        i.i_class_id,
        i.i_manufact_id,
        d.d_quarter_name,
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_quarter_name = '1900Q3'
      AND i.i_class_id IN (12, 1)
      AND sm.sm_carrier = 'UPS'
      AND sm.sm_contract = 'P7FBIt8yd'
      AND cs.cs_quantity > 1
      AND cd.cd_gender = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sm.sm_ship_mode_id, sm.sm_carrier, i.i_item_sk, i.i_item_id, i.i_class_id, i.i_manufact_id, d.d_quarter_name, cd.cd_gender
)
SELECT
    sa.c_customer_sk,
    sa.c_first_name,
    sa.c_last_name,
    sa.sm_ship_mode_id,
    sa.sm_carrier,
    sa.i_item_id,
    sa.i_class_id,
    sa.i_manufact_id,
    sa.cd_gender,
    sa.total_net_profit,
    sa.total_sales_amount,
    sa.total_quantity,
    COALESCE((
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
        WHERE wr.wr_refunded_customer_sk = sa.c_customer_sk
          AND wr.wr_item_sk = sa.i_item_sk
          AND d_ret.d_quarter_name = sa.d_quarter_name
    ), 0) AS total_return_amount,
    (sa.total_net_profit - COALESCE((
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
        WHERE wr.wr_refunded_customer_sk = sa.c_customer_sk
          AND wr.wr_item_sk = sa.i_item_sk
          AND d_ret.d_quarter_name = sa.d_quarter_name
    ), 0)) AS net_profit_after_returns,
    CASE
        WHEN (sa.total_net_profit - COALESCE((
            SELECT SUM(wr.wr_return_amt)
            FROM web_returns wr
            JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
            WHERE wr.wr_refunded_customer_sk = sa.c_customer_sk
              AND wr.wr_item_sk = sa.i_item_sk
              AND d_ret.d_quarter_name = sa.d_quarter_name
        ), 0)) > 50000 THEN 'Platinum'
        WHEN (sa.total_net_profit - COALESCE((
            SELECT SUM(wr.wr_return_amt)
            FROM web_returns wr
            JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
            WHERE wr.wr_refunded_customer_sk = sa.c_customer_sk
              AND wr.wr_item_sk = sa.i_item_sk
              AND d_ret.d_quarter_name = sa.d_quarter_name
        ), 0)) > 10000 THEN 'Gold'
        ELSE 'Silver'
    END AS profit_segment,
    RANK() OVER (PARTITION BY sa.sm_ship_mode_id ORDER BY sa.total_net_profit DESC) AS profit_rank
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE inv.inv_item_sk = sa.i_item_sk
      AND inv.inv_quantity_on_hand > 0
      AND d_inv.d_quarter_name = sa.d_quarter_name
)
ORDER BY sa.sm_ship_mode_id, profit_rank
LIMIT 100
