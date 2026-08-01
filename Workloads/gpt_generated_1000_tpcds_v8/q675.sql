WITH
    inventory_sample AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_without_returns AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        EXCEPT
        SELECT cr.cr_order_number
        FROM catalog_returns cr
    ),
    brand_union AS (
        SELECT i_brand FROM item WHERE i_brand_id < 10
        UNION ALL
        SELECT i_brand FROM item WHERE i_brand_id >= 10
    )
SELECT
    i.i_category,
    d_sales.d_year,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_profit) BETWEEN 0 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    (SELECT MAX(d_year) FROM date_dim) AS max_year
FROM
    catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sales.d_date_sk
    LEFT JOIN inventory_sample inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_open ON p.p_start_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_close ON p.p_end_date_sk = d_close.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_open.d_date_sk
WHERE
    NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = cs.cs_item_sk
          AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
    )
    AND cs.cs_order_number IN (SELECT cs_order_number FROM sales_without_returns)
GROUP BY CUBE (i.i_category, d_sales.d_year)
HAVING SUM(cs.cs_net_profit) IS NOT NULL
ORDER BY total_profit DESC
OFFSET 0 ROWS
LIMIT 100
