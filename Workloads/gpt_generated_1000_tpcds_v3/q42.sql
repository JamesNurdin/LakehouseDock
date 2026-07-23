WITH sales_return_inventory AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_rec_start_date,
        cs.cs_ext_sales_price,
        cs.cs_ext_tax,
        cs.cs_quantity,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        r.r_reason_desc,
        cd.cd_gender,
        cd.cd_dep_count,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE
        i.i_rec_start_date >= DATE '1998-01-01'
        AND i.i_current_price > 100
        AND cs.cs_ext_sales_price > 1000
        AND cs.cs_ext_tax > 20
        AND cd.cd_dep_count <= 2
        AND hd.hd_income_band_sk IN (1, 2, 3)
        AND cr.cr_return_quantity > 0
        AND inv.inv_quantity_on_hand > 50
)
SELECT
    i_item_id,
    i_product_name,
    r_reason_desc,
    cd_gender,
    total_sales,
    total_returns,
    total_net_loss,
    total_qty_sold,
    total_return_qty,
    avg_inventory,
    CASE WHEN total_net_loss > 10000 THEN 'High' ELSE 'Medium' END AS loss_category,
    RANK() OVER (PARTITION BY r_reason_desc ORDER BY total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        i_item_id,
        i_product_name,
        r_reason_desc,
        cd_gender,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(cs_quantity) AS total_qty_sold,
        SUM(cr_return_quantity) AS total_return_qty,
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM sales_return_inventory
    GROUP BY
        i_item_id,
        i_product_name,
        r_reason_desc,
        cd_gender
    HAVING
        SUM(cs_ext_sales_price) > 5000
        AND SUM(cr_net_loss) > 0
) agg
ORDER BY
    total_net_loss DESC,
    loss_rank
LIMIT 100
