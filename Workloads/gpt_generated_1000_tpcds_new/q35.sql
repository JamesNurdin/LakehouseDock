WITH
sales_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity)    AS total_quantity
    FROM catalog_sales
    WHERE cs_warehouse_sk IN (
            SELECT w_warehouse_sk
            FROM warehouse
            WHERE w_country = 'United States'
        )
      AND cs_sold_date_sk = (
            SELECT MAX(d_date_sk)
            FROM date_dim
            WHERE d_year = 2001
        )
    GROUP BY
        cs_item_sk,
        cs_sold_date_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_bill_customer_sk
),
item_sales AS (
    SELECT
        s.cs_item_sk,
        s.cs_sold_date_sk,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_brand_id,
        d.d_date,
        s.total_profit,
        s.total_quantity,
        sm.sm_type,
        w.w_warehouse_name,
        c.c_customer_id,
        LAG(s.total_profit) OVER (PARTITION BY s.cs_item_sk ORDER BY d.d_date) AS prev_day_profit
    FROM sales_agg s
    JOIN item i ON s.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
),
returns_agg AS (
    SELECT
        sr_item_sk,
        sr_returned_date_sk,
        SUM(sr_return_amt)      AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty
    FROM store_returns
    GROUP BY
        sr_item_sk,
        sr_returned_date_sk
),
item_returns AS (
    SELECT
        i_ret.i_item_sk,
        i_ret.i_item_id,
        d_ret.d_date           AS return_date,
        r.r_reason_desc,
        ra.total_return_amt,
        ra.total_return_qty
    FROM returns_agg ra
    JOIN item i_ret ON ra.sr_item_sk = i_ret.i_item_sk
    JOIN date_dim d_ret ON ra.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store_returns sr ON ra.sr_item_sk = sr.sr_item_sk
                           AND ra.sr_returned_date_sk = sr.sr_returned_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),
key_diff AS (
    SELECT cs_item_sk FROM catalog_sales
    EXCEPT
    SELECT sr_item_sk FROM store_returns
)
SELECT
    isal.i_item_id,
    isal.i_category,
    isal.i_brand,
    isal.d_date,
    isal.total_profit,
    isal.prev_day_profit,
    ir.total_return_amt,
    ir.r_reason_desc,
    isal.w_warehouse_name,
    isal.sm_type,
    isal.c_customer_id
FROM item_sales isal
LEFT JOIN item_returns ir ON isal.cs_item_sk = ir.i_item_sk
WHERE isal.cs_item_sk IN (SELECT cs_item_sk FROM key_diff)
  AND isal.i_brand_id = (SELECT MIN(i_brand_id) FROM item)
ORDER BY isal.total_profit DESC
LIMIT 100
