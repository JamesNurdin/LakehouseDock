WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MAX(cs.cs_order_number) AS sample_order_number
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk,
             cs.cs_sold_date_sk,
             cs.cs_warehouse_sk,
             cs.cs_ship_mode_sk,
             cs.cs_bill_cdemo_sk,
             cs.cs_bill_hdemo_sk
),
ranked AS (
    SELECT
        d.d_date AS d_date,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        hd.hd_buy_potential AS hd_buy_potential,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        w.w_warehouse_name AS w_warehouse_name,
        sm.sm_type AS sm_type,
        COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
        COALESCE(wr.wr_return_quantity, 0) AS web_return_qty,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        sa.total_net_paid AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sa.total_net_paid DESC) AS rn,
        CASE WHEN cr.cr_return_amount IS NOT NULL THEN 'Returned' ELSE 'NoReturn' END AS return_flag
    FROM sales_agg sa
    JOIN date_dim d
        ON sa.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON sa.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON sa.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd
        ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
       AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
       AND sr.sr_returned_date_sk = d.d_date_sk
    FULL OUTER JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON t.t_time_sk = sr.sr_return_time_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 50 AND 200
      AND hd.hd_buy_potential = '1001-5000'
      AND cr.cr_order_number NOT IN (
          SELECT DISTINCT cs.cs_order_number
          FROM catalog_sales cs
          WHERE cs.cs_quantity > 100
      )
)
SELECT DISTINCT
    d_date,
    i_item_id,
    i_product_name,
    hd_buy_potential,
    ib_lower_bound,
    ib_upper_bound,
    w_warehouse_name,
    sm_type,
    store_return_qty,
    web_return_qty,
    inv_quantity_on_hand,
    total_net_paid,
    rn,
    return_flag
FROM ranked
WHERE rn <= 5
ORDER BY total_net_paid DESC
LIMIT 100
