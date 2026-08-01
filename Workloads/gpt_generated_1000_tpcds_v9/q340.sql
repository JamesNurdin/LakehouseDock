WITH high_items AS (
    SELECT cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
    UNION
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
),
joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        td_sold.t_hour AS sold_hour,
        cs.cs_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returned_time_sk,
        td_return.t_hour AS return_hour,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        hd_bill.hd_income_band_sk,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN time_dim td_return
        ON cr.cr_returned_time_sk = td_return.t_time_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE
        i.i_current_price > 20
        AND i.i_brand = 'BrandX'
        AND i.i_category = 'Electronics'
        AND inv.inv_quantity_on_hand > 0
        AND ib.ib_upper_bound >= 100000
        AND (r.r_reason_desc LIKE '%size%' OR r.r_reason_desc LIKE '%exchange%')
        AND cs.cs_quantity > 1
        AND cs.cs_net_paid > 100
        AND i.i_item_id IS NOT NULL
        AND cs.cs_item_sk IN (SELECT item_sk FROM high_items)
),
aggregated_by_item AS (
    SELECT
        cs_item_sk AS i_item_sk,
        i_item_id,
        i_brand,
        i_category,
        SUM(cs_quantity) AS total_qty_sold,
        SUM(cs_net_paid) AS total_sales_amount,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(COALESCE(cr_return_quantity, 0)) AS total_qty_returned,
        SUM(COALESCE(cr_return_amount, 0.0)) AS total_return_amount,
        COUNT(DISTINCT cs_sold_date_sk) AS distinct_sold_dates,
        CASE WHEN SUM(cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM joined_data
    GROUP BY cs_item_sk, i_item_id, i_brand, i_category
)
SELECT
    a.i_item_id,
    a.i_brand,
    a.i_category,
    a.total_qty_sold,
    a.total_sales_amount,
    a.total_qty_returned,
    a.total_return_amount,
    a.profit_category,
    CASE
        WHEN a.total_sales_amount = 0 THEN 0
        ELSE a.total_return_amount / a.total_sales_amount
    END AS return_to_sales_ratio,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = a.i_item_sk
    ) AS avg_return_amount_per_item,
    EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = a.i_item_sk
          AND cr3.cr_return_amount > 500
    ) AS has_large_return
FROM aggregated_by_item a
WHERE a.total_sales_amount > (
    SELECT AVG(total_sales_amount) FROM aggregated_by_item
) AND a.profit_category = 'High'
ORDER BY a.total_sales_amount DESC
LIMIT 100
